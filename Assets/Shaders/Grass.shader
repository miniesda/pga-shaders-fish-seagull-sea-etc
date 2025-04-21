Shader "PGATR/Grass"
{
    Properties
    {
		[Header(Shading)]
        _TopColor("Top Color", Color) = (1,1,1,1)
		_BottomColor("Bottom Color", Color) = (1,1,1,1)
		_TranslucentGain("Translucent Gain", Range(0,1)) = 0.5
		_BendRotationRandomness("Bend Rotation Randomness", Range(0,1)) = 0.5
		_BladeWidth("Blade Width", Range(0,1)) = 0.05
		_BladeWidthRandomness("Blade Width Randomness", Range(0,1)) = 0.02
		_BladeHeight("Blade Height", Range(0,1)) = 0.5
		_BladeHeightRandomness("Blade Height Randomness", Range(0,1)) = 0.3
		_WindDistorsionMap("Wind Distorsion Map", 2D) = "white" {}
		_WindFrequency("Wind Frequency", Vector)=(0.05,0.05,0,0)
		_WindStrength("Wind Strength", Float) = 1
		_BladeForward("Blade Forward Amount", Float) = 0.38
		_BladeCurve("Blade Curvature Amount", Range(1,4)) = 2
    }

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Autolight.cginc"
	#define BLADE_SEGMENTS 3

	// Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
	// Extended discussion on this function can be found at the following link:
	// https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
	// Returns a number in the 0...1 range.
	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

	// Construct a rotation matrix that rotates around the provided axis, sourced from:
	// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
	float3x3 AngleAxis3x3(float angle, float3 axis)
	{
		float c, s;
		sincos(angle, s, c);

		float t = 1 - c;
		float x = axis.x;
		float y = axis.y;
		float z = axis.z;

		return float3x3(
			t * x * x + c, t * x * y - s * z, t * x * z + s * y,
			t * x * y + s * z, t * y * y + c, t * y * z - s * x,
			t * x * z - s * y, t * y * z + s * x, t * z * z + c
			);
	}

	struct GameOutput
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};

	GameOutput vert(float4 vertex : POSITION, float2 uv) : SV_POSITION
	{
		GameOutput go;
		go.pos = vertex;
		go.uv = uv;
		return go;
	}
	ENDCG

    SubShader
    {
		Cull Off

        Pass
        {
			Tags
			{
				"RenderType" = "Opaque"
				"LightMode" = "ForwardBase"
			}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma target 4.6
			#pragma geometry geo_shader
			
			#include "Lighting.cginc"

			float4 _TopColor;
			float4 _BottomColor;
			float _TranslucentGain;
			float _BendRotationRandomness;
			float _BladeWidth;
			float _BladeWidthRandomness;
			float _BladeHeight;
			float _BladeHeightRandomness;
			sampler2D _WindDistorsionMap;
			float4 _WindDistorsionMap_ST;
			float2 _WindFrequency;
			float _WindStrength;
			float _BladeForward;
			float _BladeCurve;

			struct VertexInput
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct VertexOutput
			{
				float4 vertex : SV_POSITION;
				float4 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			VertexOutput vert(VertexInput v)
			{
				VertexOutput o;
				o.vertex = (v.vertex);
				o.normal = (v.normal);
				o.tangent = (v.tangent);
				return o;
			}
			
			GameOutput VertexOutput2(float3 pos, float2 uv)
			{
				GameOutput go;
				go.pos = UnityObjectToClipPos(pos);
				go.uv = uv;
				return go;
			}

			GameOutput GenerateGrassVertex(float3 vertexPos, float width, float height, float forward, float2 uv, float3x3 transformMatrix)
			{
				float3 tangentPoint = float3(width, forward, height);

				float3 localPosition = vertexPos + mul(transformMatrix, tangentPoint);
				return VertexOutput2(localPosition, uv);
			}

			[maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
			void geo_shader(triangle VertexOutput IN[3], inout TriangleStream<GameOutput> tri)
			{
				float3 pos = IN[0].vertex.xyz;
				float3 normal = IN[0].normal.xyz;
				float4 tangent = IN[0].tangent.xyzw;
				float3 bitangent = cross(normal, tangent) * tangent.w;

				float3x3 tangentToLocal = float3x3(
					tangent.x, bitangent.x, normal.x,
					tangent.y, bitangent.y, normal.y,
					tangent.z, bitangent.z, normal.z
				);
				
				float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0,0,1));

				// Apply a random rotation to the grass blade
				float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandomness * UNITY_PI * 0.5, float3(-1,0,0));

				float2 uv = pos.xz * _WindDistorsionMap_ST.xy + _WindDistorsionMap_ST.zw + _Time.y * _WindFrequency;

				float2 windSample = (tex2Dlod(_WindDistorsionMap,float4(uv,0,0)).xy*2-1) * _WindStrength;

				float3 wind = normalize(float3(windSample.x, windSample.y, 0));

				float3x3 windRotationMatrix = AngleAxis3x3(UNITY_PI * windSample, wind);

				float3x3 transformationMatrix = mul(mul(mul(tangentToLocal, windRotationMatrix), facingRotationMatrix), bendRotationMatrix);
				
				float3x3 transformMatrixFacing = mul(tangentToLocal, facingRotationMatrix);
				// Apply a random width and height to the grass blade
				float height = (rand(pos.zyx)*2-1)*_BladeHeightRandomness + _BladeHeight;
				float width = (rand(pos.yxz)*2-1)*_BladeWidthRandomness + _BladeWidth;

				float forward = rand(pos.yyz)* _BladeForward;
				
				for(float i = 0; i < BLADE_SEGMENTS; i++)
				{
					float t = i/(float)BLADE_SEGMENTS;
					float segmentHeight = height * t;
					float segmentWidth = width * (1-t);
					float3x3 transformMatrix = i==0? transformMatrixFacing: transformationMatrix;
					float segmentForward = pow(t, _BladeCurve)* forward;

					tri.Append(GenerateGrassVertex(pos, segmentWidth, segmentHeight, segmentForward, float2(0,t), transformMatrix));
					tri.Append(GenerateGrassVertex(pos, -segmentWidth, segmentHeight, segmentForward, float2(1,t), transformMatrix));
				}


				tri.Append(GenerateGrassVertex(pos, 0 , height, forward, float2(0.5,1), transformationMatrix));
			}

			float4 frag (GameOutput i, fixed facing : VFACE) : SV_Target
            {	
				return lerp(_BottomColor, _TopColor, i.uv.y);
            }
            ENDCG
        }
    }
}