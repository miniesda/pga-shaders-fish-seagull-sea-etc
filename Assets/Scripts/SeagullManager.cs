using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SeagullManager : MonoBehaviour
{

    ComputeBuffer seagullBuffer;
    public ComputeShader computeShader;
    public int seagullCount = 1000;
    public GameObject seagullPrefab; // Prefab for the seagull object

    public bool Debug = true;

    [Header("Behavior Radii")]
    public float avoidanceRadius = 50f;
    public float flockingRadius = 200f;
    public float waterHeight = 20f;
    public Vector2 centerBounds = new Vector2(-1000f, 1000f);

    [Header("Behavior Weights")]
    public float pathFollowWeight = 1f;
    public float avoidanceWeight = 1f;
    public float flockingWeight = 0.5f;
    public float avoidWaterWeight = 1f;
    public float avoidCenterWeight = 1f;

    [Header("Movement")]
    public float maxSpeed = 5f;
    public float maxForce = 0.5f;

    public Vector2 SpawnRange = new Vector2(200.0f, 250.0f);

    private SeagullData[] seagulls;
    private Seagull[] seagullObjects;

    private int kernelHandler;

    private struct SeagullData
    {
        public Vector3 position;
        public Vector3 velocity;
        public Vector3 acceleration;
    }

    void OnEnable()
    {
        InitializeSeagulls();
        InitializeComputeShader();
    }

    void OnDisable()
    {
        if (seagullBuffer != null)
            seagullBuffer.Release();
    }
    
    void Update()
    {
        UpdateComputeShader();
        UpdateSeagullsObjects();
    }

    private void InitializeSeagulls(){
        seagulls = new SeagullData[seagullCount];
        seagullObjects = new Seagull[seagullCount];

        for (int i = 0; i < seagullCount; i++)
        {
            float x = Random.Range(-1900f, 1900f);
            float z = Random.Range(-1900f, 1900f);

            while ((x > -800f && x < 800f) && (z > -800f && z < 800f))
            {
                x = Random.Range(-1900f, 1900f);
                z = Random.Range(-1900f, 1900f);
            }

            Vector3 position = new Vector3(x, Random.Range(SpawnRange.x, SpawnRange.y), z);
            Vector3 velocity = Random.onUnitSphere * maxSpeed;

            seagulls[i] = new SeagullData()
            {
                position = position,
                velocity = velocity,
                acceleration = Vector3.zero
            };
            
            Quaternion randomRotation = Quaternion.Euler(0, Random.Range(0, 360), 0);
            GameObject a = Instantiate(seagullPrefab, position, randomRotation, transform);
            
            seagullObjects[i] = a.GetComponent<Seagull>();

            seagullObjects[i].Speed = velocity.magnitude;
            seagullObjects[i].Debug = Debug;
            seagullObjects[i].MaxClose = avoidanceRadius;
            seagullObjects[i].MaxFar = flockingRadius;
        }

        seagullBuffer = new ComputeBuffer(seagullCount, sizeof(float) * 9);

        seagullBuffer.SetData(seagulls);
    }

    private void InitializeComputeShader()
    {
        kernelHandler = computeShader.FindKernel("SeagullUpdate");
        computeShader.SetFloat("AvoidanceRadius", avoidanceRadius);
        computeShader.SetFloat("FlockingRadius", flockingRadius);
        computeShader.SetFloat("MaxSpeed", maxSpeed);
        computeShader.SetFloat("MaxForce", maxForce);
        computeShader.SetInt("SeagullCount", seagullCount);
        computeShader.SetFloat("avoidWaterWeight", avoidWaterWeight);
        computeShader.SetFloat("avoidCenterWeight", avoidCenterWeight);
        computeShader.SetFloat("waterHeight", waterHeight);
        computeShader.SetVector("centerBounds", centerBounds);
    }

    private void UpdateComputeShader()
{
    // Update dynamic parameters
    computeShader.SetFloat("DeltaTime", Time.deltaTime);
    computeShader.SetVector("PathCenter", transform.position);
    computeShader.SetFloat("PathFollowWeight", pathFollowWeight);
    computeShader.SetFloat("AvoidanceWeight", avoidanceWeight);
    computeShader.SetFloat("FlockingWeight", flockingWeight);
    
    // Pass the seagull count to the shader
    computeShader.SetInt("SeagullCount", seagullCount);

    // Set buffer
    computeShader.SetBuffer(kernelHandler, "Seagulls", seagullBuffer);

    // Dispatch compute shader
    int threadGroups = Mathf.CeilToInt(seagullCount / 64f);
    computeShader.Dispatch(kernelHandler, threadGroups, 1, 1);

    // Get data back from GPU
    seagullBuffer.GetData(seagulls);
}

    private void UpdateSeagullsObjects()
    {
        for (int i = 0; i < seagullCount; i++)
        {
            if (seagullObjects[i] != null)
            {
                // Update GameObject position and rotation
                seagullObjects[i].transform.position = seagulls[i].position;
                
                // Only update rotation if velocity is significant
                if (seagulls[i].velocity.sqrMagnitude > 0.01f)
                {
                    Quaternion targetRotation = Quaternion.LookRotation(seagulls[i].velocity);
                    seagullObjects[i].transform.rotation = Quaternion.Slerp(
                        seagullObjects[i].transform.rotation,
                        targetRotation,
                        Time.deltaTime * 2f
                    );
                }
                
                // Update speed for animation or other effects
                seagullObjects[i].Speed = seagulls[i].velocity.magnitude;
            }
        }
    }

}
