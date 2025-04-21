// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Ground"
{
    Properties
    {
        _Color1 ("Primer Color", Color) = (1,1,1,1) 
        _Color2 ("Segundo Color", Color) = (1,1,1,1) 
        _Color3 ("Tercer Color", Color) = (1,1,1,1)
        _Color4 ("Cuarto Color", Color) = (1,1,1,1) 
        _Color5 ("Quinto Color", Color) = (1,1,1,1)
        _Height1 ("Altura1", Float) = 10.0 
        _Height2 ("Altura2", Float) = 20.0 
        _Height3 ("Altura3", Float) = 30.0 
        _Height4 ("Altura4", Float) = 40.0 
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        Cull Off

        Pass
	{
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		
		#include "UnityCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
		};

		struct v2f
		{
			float4 vertex : SV_POSITION;
			float3 worldPos : TEXCOORD2;
		};

		float4 _Color1;
		float4 _Color2;
        float4 _Color3;
        float4 _Color4;
        float4 _Color5;
		float _Height1;
        float _Height2;
		float _Height3;
        float _Height4;

		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			return o;
		}
		
		half4 frag (v2f i) : COLOR
        {
            if (i.worldPos.y < _Height1)
            {
            return lerp(_Color1, _Color2, i.worldPos.y / _Height1);
            }
            else if (i.worldPos.y < _Height2)
            {
            return lerp(_Color2, _Color3, (i.worldPos.y - _Height1) / (_Height2 - _Height1));
            }
            else if (i.worldPos.y < _Height3)
            {
            return lerp(_Color3, _Color4, (i.worldPos.y - _Height2) / (_Height3 - _Height2));
            }
            else if (i.worldPos.y < _Height4)
            {
            return lerp(_Color4, _Color5, (i.worldPos.y - _Height3) / (_Height4 - _Height3));
            }
            else
            {
                return _Color5;
            }
		}
		ENDCG
	}
}
    FallBack "Diffuse"
}
