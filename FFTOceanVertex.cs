using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FFTOceanVertex : MonoBehaviour
{
    public Vector2Int Resolution;
    public Vector2 Wind;
    public float WindSpeed;
    public float A; // Wave height avg
    public Vector2 eplision;

    private float L; // v^2 / g

    Mesh mesh;
    Vector2[] H0;
    Vector2[] H;
    
    private float Spectrum(Vector2 k)
    {
        float dot2 = Mathf.Pow(Vector2.Dot(k, Wind), 2);
        return A * Mathf.Exp(-1 / k.magnitude * L) / Mathf.Pow(k.magnitude, 4) * dot2;
    }

    // Start is called before the first frame update
    void Start()
    {
        mesh = GetComponent<MeshFilter>().mesh;
        Wind.Normalize();
        L = WindSpeed * WindSpeed / 9.8f;

        int Nx = Resolution[0];
        int Ny = Resolution[1];
        H0 = new Vector2[Nx * Ny];
        H = new Vector2[Nx * Ny];

        for (int i = 0; i < Nx; ++i) {
            for (int j = 0; i < Ny; ++j) {
                Vector2 k = new Vector2((float)i / Nx - 0.5f, (float)j / Ny - 0.5f);
                k = 2 * Mathf.PI * k; 

                H0[i * Ny + j] = eplision * Mathf.Sqrt(Spectrum(k) / 2);
            }
        }

    }

    static Vector2 ComplexMultiply(Vector2 A, Vector2 B) {
        return new Vector2(A[0] * B[0] - A[1] * B[1], A[0] * B[1] + A[1] * B[0]);
    }

    static Vector2 conj(Vector2 A) {
        return new Vector2(A[0], -A[1]);
    }

    // Cpu code to calculate the height of each vertex
    void CalculateWavesHeight(float t) {
        int Nx = Resolution[0];
        int Ny = Resolution[1];
        // Calculate H term for the waves
        for (int i = 0; i < Nx; ++i) {
            for (int j = 0; i < Ny; ++j) {
                Vector2 k = new Vector2((float)i / Nx - 0.5f, (float)j / Ny - 0.5f);
                k = 2 * Mathf.PI * k;
                int index = i * Ny + j;
                int index2 = (Nx - i) * Ny + (Ny - j); // ..?
                float w = Mathf.Sqrt(9.8f * k.magnitude); // Dispersion
                float theta = w * t;

                // e^(iwt)
                Vector2 c1 = new Vector2(Mathf.Cos(theta), Mathf.Sin(theta));
                Vector2 c2 = new Vector2(Mathf.Cos(theta), -Mathf.Sin(theta));

                H[index] = ComplexMultiply(H0[index], c1) + ComplexMultiply(conj(H0[index2]), c2);
            }
        }

    }

    // Update is called once per frame
    void Update()
    {
        float t = Time.time;
        Debug.Log("Calculating height at time " + t);
        CalculateWavesHeight(t);

    }
}
