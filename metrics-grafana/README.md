# ACcelerators Metrics

This example aims to provide a quick how-to guide about getting the most impoortant metrics related to GPU consumption when using Large Language Models.
At this point, it is assumer that you already have Red Hat OpenShift AI running and some LLM model deployed.

You can follow the steps described in the [Granite-vLLM](../Granite-vLLM/) directory.


## Metrics

Below you can find the set of metrics that the provided Grafana board contains.

### Accelerators Metrics
- GPU Utilization: Tracks the percentage of time the GPU is actively processing tasks, indicating GPU workload levels.
- GPU Memory Utilization: Shows memory usage vs free memory, critical for identifying memory bottlenecks in GPU-heavy workloads.
- GPU Cache Utilization: Tracks the percentage of GPU memory used by the vLLM model, providing insights into memory efficiency.
- GPU Temperature: Ensures the GPU operates within safe thermal limits to prevent hardware degradation.
- GPU Throttling: It occurs when the GPU automatically reduces the clock to avoid damage from overheating


###  CPU Metrics
- CPU Utilization: node:node_cpu_utilisation:avg1m: Tracks CPU usage to identify workloads that are CPU-bound.
- CPU-GPU Bottlenecks: container_cpu_cfs_throttled_seconds_total + DCGM_FI_DEV_GPU_UTIL: A combination of CPU throttling and GPU usage metrics to identify resource allocation inefficiencies.
 
 
### vLLM Metrics
#### Request and Resource Utilization Metrics
- Running Requests: The number of requests actively being processed; helps monitor workload concurrency.
- Waiting Requests: Tracks requests in the queue, indicating system saturation.
- Prefix Cache Hit Rates: `vllm:cpu_prefix_cache_hit_rate, vllm:gpu_prefix_cache_hit_rate`: High hit rates imply efficient reuse of cached computations, optimizing resource usage.

#### Performance Metrics
- End-to-End Latency: Measures the overall time to process a request, critical for user experience.
- Request Queue Time: Indicates potential system overload or scheduling inefficiencies.
- Inference Time: Tracks the time spent in model inference, offering insights into processing efficiency.

#### Throughput Metrics 
- Time To First Token (TTFT): The time taken to generate the first token in a response.
- Time Per Output Token (TPOT): The average time taken to generate each output token.
- Prompt Throughput: Tracks the speed of processing prompt tokens, which is essential for LLM optimization.
- Generation Throughput: Measures the efficiency of generating response tokens, critical for real-time applications.
