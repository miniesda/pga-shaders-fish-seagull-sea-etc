using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Fish : MonoBehaviour
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
        rend.material.SetColor("_Color", new Color(Random.Range(0.0f, 1.0f), Random.Range(0.0f, 1.0f), Random.Range(0.0f, 1.0f)));
        rend.material.SetFloat("_TailSpeed", Random.Range(0.0f, 10.0f));
        rend.material.SetFloat("_BodyMove", Random.Range(1.0f, 10.0f));

        CloseShpere.transform.localScale = new Vector3(MaxClose, MaxClose, MaxClose);
        FarShpere.transform.localScale = new Vector3(MaxFar, MaxFar, MaxFar);

        CloseShpere.SetActive(Debug);
        FarShpere.SetActive(Debug);
    }
}
