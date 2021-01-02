﻿// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/C7-NormalMapTangentSpace" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Glossiness("Smoothness", Range(8.0,255)) = 20
	}
	SubShader{
		Pass{
		Tags{ "LightMode" = "ForwardBase" }

		CGPROGRAM

		// Use shader model 3.0 target, to get nicer looking lighting

#pragma vertex vert
#pragma fragment frag
#include "Lighting.cginc"

		struct a2v {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
			float4 texcoord : TEXCOORD0;
		};

		struct v2f {
			float4 pos : SV_POSITION;
			float4 uv : TEXCOORD0;
			float4 TtoW0 : TEXCOORD1;
			float4 TtoW1 : TEXCOORD2;
			float4 TtoW2 : TEXCOORD3;
		};

	sampler2D _MainTex;
	float4 _MainTex_ST;
	sampler2D _BumpMap;
	float4 _BumpTex_ST;
	float _BumpScale;
	float _Glossiness;
	fixed4 _Specular;
	fixed4 _Color;

	v2f vert(a2v v) {
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
		o.uv.zw = v.texcoord.xy * _BumpTex_ST.xy + _BumpTex_ST.zw;

		float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
		fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
		fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
		fixed3 worldBinormal = cross(worldTangent, worldNormal) * v.tangent.w;

		o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
		o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
		o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

		return o;
	}

	fixed4 frag(v2f i) :SV_Target{
		float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);

		fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
		fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

		fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));

		bump.xy *= _BumpScale;
		bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));

		bump = normalize(fixed3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

		fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
		fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

		fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));

		fixed3 halfDir = normalize(lightDir + viewDir);

		fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Glossiness);

		return fixed4(ambient + diffuse + specular, 1.0);

	}

		ENDCG
		}
	}
	
		Fallback "Specular"
}