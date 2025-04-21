using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Seagull : MonoBehaviour
{
    Renderer rend;

    public float Speed = 5.0f;

    public bool Debug = true;

    public GameObject CloseShpere;
    public float MaxClose = 50.0f;

    public GameObject FarShpere;
    public float MaxFar = 200.0f;

    void Start()
    {
        rend = GetComponentInChildren<Renderer>();
        rend.material.SetFloat("_TailSpeed", Random.Range(2.0f, 10.0f));
        rend.material.SetFloat("_TailAmplitude", Random.Range(1.0f, 5.0f));

        CloseShpere.transform.localScale = new Vector3(MaxClose, MaxClose, MaxClose);
        FarShpere.transform.localScale = new Vector3(MaxFar, MaxFar, MaxFar);

        CloseShpere.SetActive(Debug);
        FarShpere.SetActive(Debug);
    }
}
