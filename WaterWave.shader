// Gerstner Wave
Shader "Custom/Waves" {
	Properties {
		_ShallowColor ("Shallow Color", Color) = (1,1,1,1)
		_DeepColor("Deep Color", Color) = (1, 1, 1, 1)
		_MaxDepth("Max Depth", FLOAT) = 10
		_RefractionStrength("Refraction Strength", Range(-1, 1)) = 0.5

		_Steepness("Stepness", FLOAT) = 0.9
		_Wave0("Wave 0(Dir.x, Dir.y, Amplitude, WaveLength)", Vector) = (0, 0.2, 3, 0.1)
		_Wave1("Wave 1", Vector) = (-0.1, -0.1, 3, 0.1314)
		_Wave2("Wave 3", Vector) = (0.01, 0, 1, 0.0947)
		_Wave3("Wave 2", Vector) = (0.05, 0, 1, 0.1)
		
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0


	}
	SubShader {
		//Tags { "RenderType"="Opaque"}
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 200

		GrabPass { "_WaterBackground" }

		CGPROGRAM
		#pragma surface surf Standard alpha vertex:vert addshadow finalcolor:ResetAlpha
		#pragma target 3.0

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		sampler2D _CameraDepthTexture ,_WaterBackground;
		float4 _CameraDepthTexture_TexelSize;

		float _Steepness;
		float4 _Wave0;
		float4 _Wave1;
		float4 _Wave2;
		float4 _Wave3;
		
		half _Glossiness;
		half _Metallic;

		fixed4 _ShallowColor;
		fixed4 _DeepColor;
		float _MaxDepth;
		float _RefractionStrength;

		float3 GetSurface(float2 xy, float4 wave) 
		{
			
			float3 surface = float3(0, 0, 0);
			float t = _Time.y;
			float S = length(wave.xy);
			float2 d = normalize(wave.xy);
			float A = wave.z;
			float L = wave.w;

			if (A == 0) {
				return 0;
			}
			float steepness = _Steepness; //* L / (2 * A);
			float para = dot(d, xy) * 2 / L + t * S * 2 / L;
			float height = A * sin(para);
			
			float2 dxy = steepness * d * A * cos(para);
			return float3(dxy.x, height, dxy.y);
		}

		float3 GetPos(float3 pos, float2 xy) 
		{
			
			float3 surface = float3(0, 0, 0);
			surface += GetSurface(xy, _Wave0);
			surface += GetSurface(xy, _Wave1);
			surface += GetSurface(xy, _Wave2);
			surface += GetSurface(xy, _Wave3);

			return pos + surface;
		}


		float3 dwave(float2 xy, float4 wave) 
		{
			float t = _Time.y;
			float S = length(wave.xy);
			float2 d = normalize(wave.xy);
			float A = wave.z;
			float L = wave.w;
			if (A == 0 || L == 0) {
				return 0;
			}
			
			// float WA = 2 * A / L;
			float steepness = _Steepness;
			float para = dot(d, xy) * 2 / L + t * S * 2 / L;
			float sinW = sin(para);
			float cosW = cos(para);
			// TODO NORMAL
			return float3(-d.x * sinW, -steepness * cosW, -d.y * sinW);
		}

		float3 GetNormal(float2 xy)
		{
			float3 normal = float3(0, 0, 0);
			normal += dwave(xy, _Wave0);
			normal += dwave(xy, _Wave1);
			normal += dwave(xy, _Wave2);
			normal += dwave(xy, _Wave3);
			normal = normal / 4;
			normal += float3(0, 1, 0);

			return normalize(normal);
		}

		void vert(inout appdata_full v) 
		{
			v.vertex.xyz = GetPos(v.vertex.xyz, v.texcoord);
			v.normal  = GetNormal(v.texcoord);
		}


		struct Input {
			float2 uv_MainTex;
			float4 screenPos;
		};

		float GetDepth(float2 uv, float screenZ) 
		{
			float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
			float surfaceDepth = screenZ;
			float depthDifference = backgroundDepth - surfaceDepth;
			return depthDifference / _MaxDepth;
		}

		float3 ColorBelowWater(float2 uv, float depth) 
		{
			float3 backgroundColor = tex2D(_WaterBackground, uv).rgb;
			float transpancy = exp2(-depth);
			return backgroundColor * transpancy;
		}

		float4 GetWaterColor(float2 uv, float depth) 
		{
			return lerp(_ShallowColor, _DeepColor, depth);
		}
		
		void surf (Input IN, inout SurfaceOutputStandard o) {
			float2 uv = IN.screenPos.xy / IN.screenPos.w;
			
			#if UNITY_UV_STARTS_AT_TOP
			if (_CameraDepthTexture_TexelSize.y < 0) {
					uv.y = 1 - uv.y;
			}
			#endif
			// Fake Refraction
			// TODO stupid
			float2 uvNoise = _RefractionStrength * float2(0.01, 0.01);
			
			float depth = GetDepth(uv, UNITY_Z_0_FAR_FROM_CLIPSPACE(IN.screenPos.z));

			fixed4 color = GetWaterColor(uv, depth);
			
			o.Emission = ColorBelowWater(uv + uvNoise, depth);
			o.Albedo = color.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = 1;
		}

		void ResetAlpha (Input IN, SurfaceOutputStandard o, inout fixed4 color) {
			color.a = 1;
		}

		ENDCG
	}
}