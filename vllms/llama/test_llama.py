import requests
import json
import time
from datetime import datetime

def make_request(prompt, max_tokens=100, temperature=0.7):
    url = "https://llama-31-8b-llama-model.apps.partner.lab.com/v1/chat/completions"
    headers = {
        "Content-Type": "application/json"
    }
    data = {
        "prompt": prompt,
        "max_tokens": max_tokens,
        "temperature": temperature,
        "stream": False
    }
    
    start_time = time.time()
    response = requests.post(url, headers=headers, json=data, verify=False)
    end_time = time.time()
    
    if response.status_code == 200:
        result = response.json()
        result['request_time'] = end_time - start_time
        return result
    else:
        return {"error": response.text, "status_code": response.status_code}

# Test prompts
test_prompts = [
    "Explain quantum computing in simple terms.",
    "Write a short poem about artificial intelligence.",
    "What are the main challenges in climate change?",
    "Describe the process of photosynthesis.",
    "What is machine learning?"
]

# Run tests
results = []
for i, prompt in enumerate(test_prompts, 1):
    print(f"\nTest {i}: {prompt}")
    result = make_request(prompt)
    results.append({
        "test_number": i,
        "prompt": prompt,
        "response": result
    })
    print(json.dumps(result, indent=2))
    time.sleep(1)  # Add a small delay between requests

# Save results to file
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
with open(f"llama_test_results_{timestamp}.json", "w") as f:
    json.dump(results, f, indent=2)

# Calculate average response time
response_times = [r["response"].get("request_time", 0) for r in results if "request_time" in r["response"]]
if response_times:
    avg_time = sum(response_times) / len(response_times)
    print(f"\nAverage response time: {avg_time:.2f} seconds") 