using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FishManager : MonoBehaviour
{
    ComputeBuffer fishBuffer;
    public int fishCount = 1000;
    public ComputeShader computeShader;
    public GameObject fishPrefab;
    public bool Debug = false;

    [Header("Behavior Settings")]
    public float swimSpeed = 2f;
    public float turnSpeed = 1f;
    public float avoidanceRadius = 5f;
    public float schoolRadius = 20f;
    public float maxDepth = -60f;
    public float minDepth = -10f;

    public float AlignmentWeight = 1.0f;
    public float CohesionWeight = 1.2f;
    public float SeparationWeight = 1.5f;

    private FishData[] fishes;
    private Fish[] fishObjects;
    private int kernelHandle;
    private int threadGroupSize;

    private struct FishData
    {
        public Vector3 position;
        public Vector3 velocity;
        public Vector3 acceleration;
        public float targetDepth;
    }

    void OnEnable()
    {
        InitializeFish();
        InitializeComputeShader();
    }

    void OnDisable()
    {
        if (fishBuffer != null)
            fishBuffer.Release();
    }

    void Update()
    {
        UpdateComputeShader();
        UpdateFishObjects();
    }

    private void InitializeFish()
    {
        fishes = new FishData[fishCount];
        fishObjects = new Fish[fishCount];
        fishBuffer = new ComputeBuffer(fishCount, 10 * sizeof(float)); // 10 floats per fish

        for (int i = 0; i < fishCount; i++)
        {
            float x = Random.Range(-1900f, 1900f);
            float z = Random.Range(-1900f, 1900f);

            // Avoid center area
            while ((x > -800f && x < 800f) && (z > -800f && z < 800f))
            {
                x = Random.Range(-1900f, 1900f);
                z = Random.Range(-1900f, 1900f);
            }

            Vector3 position = new Vector3(x, Random.Range(maxDepth, minDepth), z);
            Vector3 velocity = Random.insideUnitSphere * swimSpeed;
            velocity.y = 0; // Start with horizontal movement

            fishes[i] = new FishData()
            {
                position = position,
                velocity = velocity,
                acceleration = Vector3.zero,
                targetDepth = position.y
            };

            Quaternion randomRotation = Quaternion.Euler(0, Random.Range(0, 360), 0);
            GameObject fishObj = Instantiate(fishPrefab, position, randomRotation, transform);
            fishObjects[i] = fishObj.GetComponent<Fish>();
            
            if (fishObjects[i] != null)
            {
                fishObjects[i].Speed = velocity.magnitude;
                fishObjects[i].Debug = Debug;
            }
        }

        fishBuffer.SetData(fishes);
    }

    private void InitializeComputeShader()
    {
        // Find the kernel and check if it exists
            kernelHandle = computeShader.FindKernel("FishUpdate");
            uint threadGroupSizeX;
            computeShader.GetKernelThreadGroupSizes(kernelHandle, out threadGroupSizeX, out _, out _);
            threadGroupSize = (int)threadGroupSizeX;

            computeShader.SetBuffer(kernelHandle, "Fishes", fishBuffer);
            computeShader.SetInt("FishCount", fishCount);
            computeShader.SetFloat("SwimSpeed", swimSpeed);
            computeShader.SetFloat("TurnSpeed", turnSpeed);
            computeShader.SetFloat("AvoidanceRadius", avoidanceRadius);
            computeShader.SetFloat("SchoolRadius", schoolRadius);
            computeShader.SetFloat("MaxDepth", maxDepth);
            computeShader.SetFloat("MinDepth", minDepth);
            computeShader.SetFloat("AlignmentWeight", AlignmentWeight);
            computeShader.SetFloat("CohesionWeight", CohesionWeight);
            computeShader.SetFloat("SeparationWeight", SeparationWeight);
    }

    private void UpdateComputeShader()
    {
        if (computeShader == null || fishBuffer == null) return;

        // Update dynamic parameters
        computeShader.SetFloat("DeltaTime", Time.deltaTime);

        // Dispatch compute shader
        int threadGroups = Mathf.CeilToInt(fishCount / (float)threadGroupSize);
        computeShader.Dispatch(kernelHandle, threadGroups, 1, 1);

        // Get data back from GPU
        fishBuffer.GetData(fishes);
    }

    private void UpdateFishObjects()
    {
        for (int i = 0; i < fishCount; i++)
        {
            if (fishObjects[i] != null)
            {
                fishObjects[i].transform.position = fishes[i].position;
                
                if (fishes[i].velocity.sqrMagnitude > 0.01f)
                {
                    Quaternion targetRotation = Quaternion.LookRotation(fishes[i].velocity);
                    fishObjects[i].transform.rotation = Quaternion.Slerp(
                        fishObjects[i].transform.rotation,
                        targetRotation,
                        Time.deltaTime * 2f
                    );
                }
                
                fishObjects[i].Speed = fishes[i].velocity.magnitude;
            }
        }
    }
}