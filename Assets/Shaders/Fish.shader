Shader "Custom/FishGeoShader"
{
    Properties
    {
        _MainTex ("Fish Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _TailSpeed ("Tail Speed", Range(0, 10)) = 2.0
        _TailAmplitude ("Tail Amplitude", Range(0, 2)) = 0.5
        _FishLength ("Fish Length", Range(0.1, 3)) = 1.5
        _FishWidth ("Fish Width", Range(0.1, 1)) = 0.3
        _BodyMove ("Body Move", Range(1, 10)) = 5.0
        _Size ("Size", Range(0.1, 10)) = 1.0
    }
    
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 200
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #pragma target 4.0
            
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _TailSpeed;
            float _TailAmplitude;
            float _FishLength;
            float _FishWidth;
            float _BodyMove;
            float _Size;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2g
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            v2g vert (appdata v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.uv = v.uv;
                return o;
            }

            [maxvertexcount(24)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> triStream)
            {
                g2f o;
                
                float length = _FishLength;
                float width = _FishWidth;
                float tailLength = length * 0.4;
                float4 _Offset = float4(0.0, -_Size, 0.0, 0.0);
                
                // Calculate tail movement
                float wave = sin(_Time.y * _TailSpeed) * _TailAmplitude;
                
                // Create fish body vertices (simplified fish shape)
                float3 bodyVertices[4];
                float2 uv[6] = {
                    float2(1, 0), 
                    float2(1, 1),   
                    float2(0.35, 0),   
                    float2(0.3, 1),
                    float2(0, 0),
                    float2(0, 1)
                };
                
                bodyVertices[0] = float3(0, 0, width);
                bodyVertices[1] = float3(0, 0,-width);
                bodyVertices[2] = float3(0, 1, 0) + float3(wave / _BodyMove, length, width);
                bodyVertices[3] = float3(0, 1, 0) + float3(wave / _BodyMove, length, -width);

                //Attach body vertices to the geometry shader output
                for (int i = 0; i < 4; i++)
                {
                    o.pos = UnityObjectToClipPos(input[0].vertex + float4(bodyVertices[i], 0) * _Size + _Offset);
                    o.uv = uv[i];
                    o.normal = float3(0, 1, 0);
                    triStream.Append(o);
                }

                // Create tail vertices (simplified tail shape)
                float3 tailVertices[4];

                tailVertices[0] = bodyVertices[2];
                tailVertices[1] = bodyVertices[3];
                tailVertices[2] = bodyVertices[2] + float3(wave, length, 0);
                tailVertices[3] = bodyVertices[3] + float3(wave, length, 0);

                // Attach tail vertices to the geometry shader output
                for (int i = 0; i < 4; i++)
                {
                    o.pos = UnityObjectToClipPos(input[0].vertex + float4(tailVertices[i], 0) * _Size + _Offset);
                    o.uv = uv[i+2];
                    o.normal = float3(0, 1, 0);
                    triStream.Append(o);
                }
            }

            fixed4 frag (g2f i) : SV_Target
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