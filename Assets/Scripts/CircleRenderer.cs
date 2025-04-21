using UnityEngine;

public class CircleRenderer : MonoBehaviour {
    public LineRenderer lineRenderer;
    public int segments = 36; // Number of segments (more = smoother)
    public float radius = 1f; // Radius of the circle

    void Start() {
        lineRenderer.positionCount = segments + 1; // +1 for closing the circle
        lineRenderer.useWorldSpace = false; // Use local space

        for (int i = 0; i <= segments; i++) {
            float angle = Mathf.PI * 2 * i / segments; // Calculate the angle
            float x = radius * Mathf.Cos(angle); // Calculate x-coordinate
            float y = radius * Mathf.Sin(angle); // Calculate y-coordinate
            lineRenderer.SetPosition(i, new Vector3(x, 0, y)); // Set the point
        }
    }
}