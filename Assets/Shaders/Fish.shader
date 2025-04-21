Shader "Custom/Fish"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)

        //Colors to control speed of sine wave

        _TailSpeed ("Tail Speed", Range(0, 10)) = 1.0
        _TailAmplitude ("Tail Amplitude", Range(0, 5)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.0

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _TailSpeed;
            float _TailAmplitude;
            
            #include "UnityCG.cginc"

            struct VertexInput
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct VertexOutput
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            // Vertex shader
            VertexOutput vert (VertexInput v)
            {
                VertexOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;

                float4 moveColor = lerp(float4(1.0f, 1.0f, 1.0f, 1.0f), float4(0.0f, 0.0f, 0.0f, 1.0f), v.uv.x);
                float wave = sin(_Time.y * _TailSpeed) * _TailAmplitude;

                o.vertex.x += wave * moveColor;
                return o;
            }


            // Fragment shader
            float4 frag (VertexOutput i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                clip(col.a - 0.01);
                return col;
            }
        ENDCG
        }
    }
    FallBack "Opaque"
}