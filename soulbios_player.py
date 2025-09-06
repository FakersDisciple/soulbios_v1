import httpx
import time
import logging
import json
import argparse
from collections import deque
import queue

# --- Configuration ---
CHALLENGE_BASE_URL = "https://berghain.challenges.listenlabs.ai"
PLAYER_ID = "c34ce284-f656-43c1-b221-0f4f94718fe5"
# Updated to current deployed URL
SOULBIOS_API_URL = "https://soulbios-v1-747hyhhxdq-uc.a.run.app" 
SOULBIOS_API_KEY = "FVaiUzD7ipeSQi37RcuGQAbIsjkGqed8S0J2IT0znsnFolkPTAHfvceAYbAkNJc5" 

# --- Bayesian Parameter ---
STRATEGIC_REVIEW_INTERVAL = 100 # How often to pause and consult SoulBios

# --- Global Variables ---
_strategy_cache = {}
prompt_queue = queue.Queue()

# --- Setup ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logging.getLogger("httpx").setLevel(logging.WARNING)

def get_soulbios_strategy(prompt: str, soulbios_client: httpx.Client, fallback_strategy: dict, force_update: bool = False) -> dict:
    """Makes a specialized API call to the SoulBios Game Theory engine."""
    try:
        logging.info("🧠 Consulting SoulBios CloudStudentAgent orchestration system for strategic guidance...")
        # Updated for the current API structure
        response = soulbios_client.post("/v1/berghain/strategize", json={"prompt": prompt})
        response.raise_for_status()
        # The endpoint returns clean JSON directly
        strategy = response.json()
        
        # Handle potential metadata in response
        if "_ooda_metadata" in strategy:
            processing_time = strategy["_ooda_metadata"].get("processing_time_ms", 0)
            logging.info(f"✅ SoulBios orchestrated strategy in {processing_time}ms: {strategy['policy_type']}")
        else:
            logging.info(f"✅ SoulBios architected new strategy: {strategy}")
        return strategy
    except httpx.HTTPStatusError as e:
        logging.error(f"SoulBios API error ({e.response.status_code}): {e.response.text}")
        return fallback_strategy
    except httpx.TimeoutException:
        logging.error("SoulBios API timeout. Using fallback strategy.")
        return fallback_strategy
    except Exception as e:
        logging.error(f"Failed to get strategy from SoulBios: {e}. Using fallback strategy.")
        return fallback_strategy

def batch_processor(soulbios_client):
    """Batch processor for multiple prompts - currently unused in single-prompt mode"""
    while True:
        prompts = []
        while not prompt_queue.empty():
            prompts.append(prompt_queue.get())
        if prompts:
            logging.debug(f"📤 Sending batched prompts to /v1/berghain/strategize: {prompts}")
            try:
                start_time = time.time()
                logging.info(f"📦 Processing batch of {len(prompts)} prompts")
                response = soulbios_client.post("/v1/berghain/strategize", json={"prompts": prompts}, timeout=120.0)
                logging.info(f"✅ Batch processed in {(time.time() - start_time) * 1000:.1f}ms")
            except Exception as e:
                logging.error(f"❌ Batch processing failed: {e}")
        time.sleep(0.1)

class BouncerPolicy:
    """A universal bouncer whose strategy can be updated in real-time by the SoulBios engine."""
    def __init__(self, constraints: dict, strategy: dict):
        self.constraints = {c['attribute']: {"target": c['minCount'], "admitted": 0} for c in constraints}
        self.set_strategy(strategy)
        self.reset()

    def set_strategy(self, strategy: dict):
        self.strategy = strategy
        policy_type = strategy.get("policy_type", "Unknown")
        switch_point = strategy.get("phase_switch_point", "N/A")
        logging.info(f"🎯 Policy UPDATED to: {policy_type} (switch@{switch_point})")

    def reset(self):
        self.slots_filled = 0
        self.rejections = 0
        self.slots_remaining = 1000
        self.recent_decisions = []  # Track recent accept/reject decisions for emergency detection
        for attr in self.constraints: self.constraints[attr]['admitted'] = 0

    def update_state(self, accepted: bool, person_attributes: dict):
        # Track recent decisions for emergency detection
        self.recent_decisions.append(accepted)
        # Keep only the last 25 decisions
        if len(self.recent_decisions) > 25:
            self.recent_decisions.pop(0)
            
        if accepted:
            self.slots_filled += 1
            self._record_admission(person_attributes)
        else:
            self.rejections += 1
        self.slots_remaining = 1000 - self.slots_filled

    def _record_admission(self, person_attributes: dict):
        for attr, has_attr in person_attributes.items():
            if has_attr and attr in self.constraints:
                self.constraints[attr]["admitted"] += 1

    def should_admit(self, person_attributes: dict) -> bool:
        # --- PANIC MODE: Critical constraint check ---
        for attr, data in self.constraints.items():
            needed = data['target'] - data['admitted']
            if self.slots_remaining > 0 and needed >= self.slots_remaining:
                if person_attributes.get(attr, False):
                    logging.warning(f"🚨 PANIC MODE: Must admit for constraint '{attr}'. Needed: {needed}, Slots Left: {self.slots_remaining}")
                    return True # Must admit, we have no choice.
        # --- END PANIC MODE ---

        policy_type = self.strategy.get("policy_type", "Hybrid")
        if policy_type == "Hybrid" and self.slots_filled < self.strategy.get("phase_switch_point", 400):
            return self._max_urgency_logic(person_attributes)
        elif policy_type == "MaxUrgency":
            return self._max_urgency_logic(person_attributes)
        else:
            return self._combined_value_logic(person_attributes)

    def _max_urgency_logic(self, person_attributes: dict) -> bool:
        params = self.strategy.get("early_game_params", {})
        base_leniency = params.get("base_leniency", 0.55)
        scaling_factor = params.get("scaling_factor", 0.4)
        
        urgencies = []
        for attr, has_attr in person_attributes.items():
            if has_attr and attr in self.constraints and self.slots_remaining > 0:
                needed = self.constraints[attr]['target'] - self.constraints[attr]['admitted']
                urgency = needed / self.slots_remaining
                urgencies.append(urgency)
        
        if not urgencies: return False
        max_urgency = max(urgencies)
        
        if max_urgency >= 1.0: return True
        dynamic_threshold = base_leniency + (scaling_factor * (self.slots_filled / 1000))
        return max_urgency >= dynamic_threshold

    def _combined_value_logic(self, person_attributes: dict) -> bool:
        params = self.strategy.get("late_game_params", {})
        base_threshold = params.get("base_threshold", 0.75)
        buffer_percent = params.get("buffer_percent", 0.1)  # Support new buffer parameter
        
        combined_urgency = 0
        for attr, has_attr in person_attributes.items():
            if has_attr and attr in self.constraints and self.slots_remaining > 0:
                needed = self.constraints[attr]['target'] - self.constraints[attr]['admitted']
                urgency = needed / self.slots_remaining
                combined_urgency += urgency
        
        if combined_urgency == 0: return False
        if combined_urgency >= (1.0 + buffer_percent): return True
        return combined_urgency >= base_threshold

    def get_acceptance_rate_in_window(self, window_size: int = 25) -> float:
        """Calculate acceptance rate in the recent decision window"""
        if not self.recent_decisions or len(self.recent_decisions) < window_size:
            return 1.0  # Default to optimistic if insufficient data
        
        recent_window = self.recent_decisions[-window_size:]
        acceptances = sum(1 for decision in recent_window if decision)
        return acceptances / len(recent_window)

def play_game(scenario_id: int, client: httpx.Client, soulbios_client: httpx.Client) -> int:
    logging.info(f"🎮 Starting Bayesian Bouncer Run: Scenario {scenario_id}")
    try:
        game_data = client.get(f"/new-game?scenario={scenario_id}&playerId={PLAYER_ID}").json()
        game_id = game_data['gameId']
        
        # Enhanced initial prompt for CloudStudentAgent orchestration
        initial_prompt = json.dumps({
            "current_person": 1,
            "accepted_count": 0,
            "constraints": game_data.get('constraints', []),
            "observedFrequencies": game_data.get('attributeStatistics', {}).get('relativeFrequencies', {}),
            "attributeStatistics": game_data.get('attributeStatistics', {}),
            "current_game_state": {
                "slots_filled": 0,
                "slots_remaining": 1000,
                "scenario_id": scenario_id
            },
            "mission": f"Design optimal bouncer policy for scenario {scenario_id}. Consider constraint urgency, attribute frequencies, and multi-phase strategy."
        })
        
        fallback_strategy = {
            "policy_type": "Hybrid", 
            "phase_switch_point": 400, 
            "early_game_params": {"base_leniency": 0.55, "scaling_factor": 0.4}, 
            "late_game_params": {"base_threshold": 0.75}
        }
        
        logging.info("🧠 Requesting initial strategy from SoulBios CloudStudentAgent...")
        strategy = get_soulbios_strategy(initial_prompt, soulbios_client, fallback_strategy)
        policy = BouncerPolicy(game_data['constraints'], strategy)
        
        response = client.get(f"/decide-and-next?gameId={game_id}&personIndex=0").json()
    except Exception as e:
        logging.error(f"❌ Failed during game initialization: {e}", exc_info=True)
        return -1

    observation_window = deque(maxlen=STRATEGIC_REVIEW_INTERVAL)
    while True:
        current_person = response.get('nextPerson')
        if not current_person: 
            final_score = response.get('rejectedCount', -1)
            logging.info(f"🎉 Game completed with {final_score} rejections")
            return final_score

        person_index = current_person['personIndex']
        observation_window.append(current_person['attributes'])

        # --- EMERGENCY FAILURE DETECTION ---
        # After person 450, if we've had a long streak of rejections
        # and haven't accepted anyone recently, force a review.
        recent_acceptance_window = 25
        emergency_triggered = False
        if (person_index > 450 and 
            person_index % STRATEGIC_REVIEW_INTERVAL != 0 and  # Not already doing scheduled review
            len(policy.recent_decisions) >= recent_acceptance_window and
            policy.get_acceptance_rate_in_window(recent_acceptance_window) == 0):
            
            logging.warning(f"🚨 EMERGENCY REVIEW @ Person #{person_index}: Zero acceptance detected in the last {recent_acceptance_window} attempts!")
            emergency_triggered = True

        if person_index > 0 and (person_index % STRATEGIC_REVIEW_INTERVAL == 0 or emergency_triggered):
            review_type = "🚨 EMERGENCY" if emergency_triggered else "🔍 STRATEGIC"
            logging.warning(f"{review_type} REVIEW @ Person #{person_index}")
            observed_freq = {attr: sum(1 for p in observation_window if p.get(attr, False)) / len(observation_window) for attr in policy.constraints}
            
            # Enhanced mid-game adaptation prompt
            mid_game_prompt = json.dumps({
                "current_person": person_index,
                "accepted_count": policy.slots_filled,
                "constraints": [{"attribute": attr, "minCount": data["target"], "admitted": data["admitted"]} for attr, data in policy.constraints.items()],
                "observedFrequencies": observed_freq,
                "attributeStatistics": game_data.get('attributeStatistics', {}),
                "current_game_state": {
                    "slots_filled": policy.slots_filled,
                    "slots_remaining": policy.slots_remaining,
                    "scenario_id": scenario_id
                },
                "current_strategy": policy.strategy,
                "mission": f"{'🚨 EMERGENCY ADAPTATION REQUIRED: Zero acceptance rate detected! ' if emergency_triggered else ''}Bayesian update: Adapt strategy based on observed vs expected frequencies. Current progress: {policy.slots_filled}/1000 slots filled."
            })
            
            logging.info("🧠 Requesting strategy adaptation from SoulBios CloudStudentAgent...")
            new_strategy = get_soulbios_strategy(mid_game_prompt, soulbios_client, policy.strategy)
            policy.set_strategy(new_strategy)
            
        admit = policy.should_admit(current_person['attributes'])
        policy.update_state(admit, current_person['attributes'])
        
        try:
            params = {"gameId": game_id, "personIndex": person_index, 'accept': str(admit).lower()}
            response = client.get("/decide-and-next", params=params).json()
        except Exception as e:
            logging.error(f"❌ API error at P#{person_index}: {e}")
            return -1

        if response['status'] == 'completed':
            final_score = response['rejectedCount']
            logging.info(f"🎉 GAME COMPLETED with {final_score} rejections")
            return final_score
        elif response['status'] == 'failed':
            logging.error(f"❌ GAME FAILED: {response.get('reason')}")
            return -1

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="A real-time adaptive player for the Berghain Challenge, powered by the SoulBios CloudStudentAgent orchestration system.")
    parser.add_argument("-s", "--scenarios", nargs='+', type=int, default=[1, 2, 3], help="A list of scenario numbers to play.")
    args = parser.parse_args()
    
    challenge_client = httpx.Client(base_url=CHALLENGE_BASE_URL, timeout=30.0)
    soulbios_client = httpx.Client(
        base_url=SOULBIOS_API_URL, 
        timeout=120.0,  # Extended timeout for agent orchestration
        headers={
            "Authorization": f"Bearer {SOULBIOS_API_KEY}",
            "Content-Type": "application/json"
        }
    )
    
    print("\n" + "="*50)
    print("    🧠 SOULBIOS BAYESIAN BOUNCER v2.0    ")
    print("    Powered by CloudStudentAgent Orchestration")
    print("="*50)
    
    total_rejections = 0
    results = {}
    
    for scenario in args.scenarios:
        print(f"\n🎯 Starting Scenario {scenario}...")
        score = play_game(scenario, challenge_client, soulbios_client)
        results[f"Scenario {scenario}"] = score
        if score != -1:
            total_rejections += score
            print(f"✅ Scenario {scenario} completed: {score} rejections")
        else:
            logging.error("❌ Game failed, stopping run.")
            break
            
    print("\n" + "="*50)
    print("    🏆 BAYESIAN BOUNCER RESULTS    ")
    print("="*50)
    for scenario, score in results.items():
        status = "✅" if score != -1 else "❌"
        print(f"{status} {scenario}: {score} rejections")
    print("-"*50)
    print(f"🎯 TOTAL REJECTIONS: {total_rejections}")
    print(f"🧠 Powered by SoulBios CloudStudentAgent")
    print("="*50)
    
    challenge_client.close()
    soulbios_client.close()