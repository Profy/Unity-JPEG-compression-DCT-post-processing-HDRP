Shader "Hidden/Shader/DCTArtifacts"
{
	Properties
	{
		// This property is necessary to make the CommandBuffer.Blit bind the source texture to _MainTex
		_MainTex("", 2DArray) = "" {}
	}

	HLSLINCLUDE

	#pragma target 4.5
	#pragma only_renderers d3d11 vulkan metal

	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
	#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"

	#define SQRT2 0.70710678118

	struct Attributes
	{
		uint vertexID : SV_VertexID;
	};
	struct Varyings
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};

	Varyings Vert(Attributes v)
	{
		Varyings o;
		o.pos = GetFullScreenTriangleVertexPosition(v.vertexID);
		o.uv = GetFullScreenTriangleTexCoord(v.vertexID);
		return o;
	}

	TEXTURE2D_X(_MainTex);

	uint _Level;

	// This is the discrete cosine transform step, where 8x8 blocs are converted into frequency space
	float DCTcoeff(float2 k, float2 x)
	{
		return cos(PI * k.x * x.x) * cos(PI * k.y * x.y);
	}
	
	// DCT compression
	float3 DCT(Varyings i) : SV_Target
	{
		int2 resolution = round(i.pos.xy / i.uv.xy);
		float2 fragCoord = i.uv * resolution.xy;

		float2 k = fmod(fragCoord, 8) - 0.5;
		float2 K = fragCoord - k - 0.5;

		float3 val;
		for (int x = 0; x < 8; ++x)
		{
		 	for (int y = 0; y < 8; ++y)
			{
		 		val += SAMPLE_TEXTURE2D_X(_MainTex, s_linear_clamp_sampler, (K + float2(x, y) + 0.5) / resolution.xy).rgb * DCTcoeff(k, (float2(x, y) + 0.5) / 8) * (k.x < 0.5 ? SQRT2 : 1) * (k.y < 0.5 ? SQRT2 : 1);
			}
		}

		return round(float3(val / 4) * _Level) / _Level;
	}
	// Inverse DCT effect
	float3 IDCT(Varyings i) : SV_Target
	{
		int2 resolution = round(i.pos.xy / i.uv.xy);
		float2 fragCoord = i.uv * resolution.xy;

		float2 k = fmod(fragCoord, 8) - 0.5;
		float2 K = fragCoord - k - 0.5;

		float3 val;
		for (int x = 0; x < 8; ++x)
		{
			for (int y = 0; y < 8; ++y)
			{
		 		val += SAMPLE_TEXTURE2D_X(_MainTex, s_linear_clamp_sampler, (K + float2(x, y) + 0.5) / resolution.xy).rgb * DCTcoeff(float2(x, y), (k + 0.5) / 8) * (x == 0 ? SQRT2 : 1) * (y == 0 ? SQRT2 : 1);
			}
		}
		return float3(val / 4);
	}

	ENDHLSL

	SubShader
	{
		ZWrite Off ZTest Always Blend Off Cull Off

		// DCT
		Pass
		{
			HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment DCT
			ENDHLSL
		}

		// IDCT
		Pass
		{
			HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment IDCT
			ENDHLSL
		}
	}
	Fallback Off
}