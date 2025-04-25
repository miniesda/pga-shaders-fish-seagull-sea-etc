Shader "Custom/TessellatedSeaShader" {
    Properties {
        _TessellationFactorMin ("Min Tessellation", Range(1, 32)) = 3
        _TessellationFactorMax ("Max Tessellation", Range(1, 64)) = 15
        _TessellationDistance ("Tessellation Distance", Float) = 3000
        _WaveHeight ("Wave Height", Float) = -100
        _WavePattern ("Wave Pattern, Perlin Noise", 2D) = "white" {}
        _WaveDirection ("Wave Direction", Vector) = (-100,100, 0, 0)
        _Scale ("Scale", Range(0.00000001, 0.001)) = 0.000001
        _Color1 ("Color 1", Color) = (0,0,1,1)
        _Color2 ("Color 2", Color) = (0,1,1,1)    
        _levels ("Levels", Range(0, 100)) = 0.5
    }

    SubShader {
        Tags { "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 200
        Cull Off
        
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma fragment frag
            #pragma target 4.6

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            struct TessellationFactors {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            float _TessellationFactorMin;
            float _TessellationFactorMax;
            float _TessellationDistance;
            float _WaveHeight;
            sampler2D _WavePattern;
            float4 _WavePattern_ST;
            float4 _WaveDirection;
            float4 _Color1;
            float4 _Color2;
            float _Scale;
            float _levels;
            // Vertex shader - pass through data
            appdata vert (appdata v) {
                return v;
            }

            // Calculate tessellation factor based on camera distance
            float CalculateTessellationFactor(float3 position) {
                float distanceToCamera = distance(_WorldSpaceCameraPos, mul(unity_ObjectToWorld, float4(position, 1)).xyz);
                return clamp(_TessellationFactorMax * (1 - saturate(distanceToCamera / _TessellationDistance)), 
                           _TessellationFactorMin, _TessellationFactorMax);
            }

            // Hull shader constant function
            TessellationFactors hullConstant(InputPatch<appdata, 3> patch) {
                TessellationFactors tf;
                
                // Calculate midpoint positions for each edge
                float3 edge0Midpoint = (patch[0].vertex + patch[1].vertex) * 0.5;
                float3 edge1Midpoint = (patch[1].vertex + patch[2].vertex) * 0.5;
                float3 edge2Midpoint = (patch[2].vertex + patch[0].vertex) * 0.5;

                tf.edge[0] = CalculateTessellationFactor(edge0Midpoint);
                tf.edge[1] = CalculateTessellationFactor(edge1Midpoint);
                tf.edge[2] = CalculateTessellationFactor(edge2Midpoint);
                tf.inside = (tf.edge[0] + tf.edge[1] + tf.edge[2]) / 3.0;
                
                return tf;
            }

            // Hull shader
            [domain("tri")]
            [outputcontrolpoints(3)]
            [outputtopology("triangle_cw")]
            [partitioning("fractional_odd")]
            [patchconstantfunc("hullConstant")]
            appdata hull(InputPatch<appdata, 3> patch, uint id : SV_OutputControlPointID) {
                return patch[id];
            }

            // Domain shader - calculate final vertex positions
            [domain("tri")]
            v2f domain(TessellationFactors factors, 
                     const OutputPatch<appdata, 3> patch, 
                     float3 barycentricCoordinates : SV_DomainLocation) {
                
                // Interpolate vertex attributes
                appdata v;
                v.vertex = patch[0].vertex * barycentricCoordinates.x +
                          patch[1].vertex * barycentricCoordinates.y +
                          patch[2].vertex * barycentricCoordinates.z;

                v.normal = patch[0].normal * barycentricCoordinates.x +
                          patch[1].normal * barycentricCoordinates.y +
                          patch[2].normal * barycentricCoordinates.z;
                
                v.normal = normalize(v.normal); // Normalize the interpolated normal


                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; // Transform to world space
                
                float2 uv = _Scale * (_Time.y * _WaveDirection.xy + o.worldPos.xz); // Calculate UV coordinates based on time and wave direction
                float Height = tex2Dlod(_WavePattern, float4(uv,0,0)).r * _WaveHeight; // Sample the wave pattern texture and multiply by wave height
                o.worldPos.y -= Height; // Adjust the world position based on the wave height
                o.vertex.y -= Height; // Adjust the vertex position based on the wave height

                float3 dx = tex2Dlod(_WavePattern, float4(uv + float2(0.1,0),0,0)).r * _WaveHeight;
                float3 dz = tex2Dlod(_WavePattern, float4(uv + float2(0,0.1),0,0)).r * _WaveHeight;
                o.normal = normalize(cross(dz, dx));
    
                // Use the calculated normal from height map
                //o.normal = UnityObjectToWorldNormal(normal);
                return o;

            }

            // Fragment shader (same as before)
            float4 frag(v2f i) : SV_Target {

                float4 color1 = lerp(_Color1, _Color2, pow((i.worldPos.y + _levels),2));
                //float4 color2 = lerp(_Color1, _Color2, pow((i.worldPos.y + _levels),3));

                return color1;
            }
            ENDCG
        }
    }
    FallBack "Transparent"
}