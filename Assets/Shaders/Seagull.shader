Shader "Custom/Seagull"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)

        //Colors to control speed of sine wave

        _TailSpeed ("Tail Speed", Range(0, 10)) = 1.0
        _TailAmplitude ("Tail Amplitude", Range(2.0, 10.0)) = 3.0
        _BodyLength ("Body Length", Range(0.1, 3)) = 1.5
        _BodyWidth ("Body Width", Range(0.1, 1)) = 0.3
        _BodyMove ("Body Move", Range(1, 50)) = 5.0
        _Size ("Size", Range(1, 100)) = 50.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 200
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #pragma target 4.0

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _TailSpeed;
            float _TailAmplitude;
            float _BodyLength;
            float _BodyWidth;
            float _BodyMove;
            float _Size;
            
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

                //Using a unity plane
                //float4 moveColor = lerp(float4(1.0f, 1.0f, 1.0f, 1.0f), float4(0.0f, 0.0f, 0.0f, 1.0f), v.uv.x * 2);
                //float wave = sin(_Time.y * _TailSpeed) * _TailAmplitude;

                //o.vertex.y += pow(wave * moveColor,2);
                return o;
            }

            //Geometry shader only 1 triangle input
            [maxvertexcount(8)]
            void geom (triangle VertexOutput input[3], inout TriangleStream<VertexOutput> triStream)
            {
                VertexOutput o;
                float BodyLength = _BodyLength;
                float BodyWidth = _BodyWidth;
                float BodyMove = _BodyMove;
                float Size = _Size;
                float body = 0.05;

                float wave = sin(_Time.y * _TailSpeed) / _TailAmplitude;

                float4 _Offset = float4(-1.5, 0.0, 0.0, 0.0);

                float3 bodyVertices[8];
                float2 uv[8] = {
                    float2(1, 1), 
                    float2(1, 0), 
                    float2(0.55, 1), 
                    float2(0.55, 0), 
                    float2(0.45, 1), 
                    float2(0.45, 0), 
                    float2(0, 1), 
                    float2(0, 0) 
                };

                bodyVertices[0] = float3(-BodyWidth, -pow(wave,2), -BodyLength);
                bodyVertices[1] = float3(-BodyWidth, -pow(wave,2), BodyLength);
                bodyVertices[2] = float3(-body, -pow(wave,2) / BodyMove, -BodyLength);
                bodyVertices[3] = float3(-body, -pow(wave,2) / BodyMove, BodyLength);
                bodyVertices[4] = float3(body, -pow(wave,2) / BodyMove, -BodyLength);
                bodyVertices[5] = float3(body, -pow(wave,2) / BodyMove, BodyLength);
                bodyVertices[6] = float3(BodyWidth, -pow(wave,2), -BodyLength);
                bodyVertices[7] = float3(BodyWidth, -pow(wave,2), BodyLength);

                for (int i = 0; i < 8; i++)
                {
                    o.vertex = UnityObjectToClipPos(float4(bodyVertices[i], 0) * _Size + _Offset);
                    o.uv = uv[i];
                    o.normal = input[0].normal;
                    triStream.Append(o);
                }
                
                triStream.RestartStrip();
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
    FallBack "Transparent"
}