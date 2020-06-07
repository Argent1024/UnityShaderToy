// Gerstner Wave
Shader "Custom/Waves" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
	
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
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows vertex:vert
		#pragma target 3.0

		sampler2D _MainTex;
		float _Steepness;
		float4 _Wave0;
		float4 _Wave1;
		float4 _Wave2;
		float4 _Wave3;
		

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

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
			if (A == 0) {
				return 0;
			}
			
			float steepness = _Steepness;
			float para = dot(d, xy) * 2 / L + t * S * 2 / L;
			float sinW = sin(para);
			float cosW = cos(para);
			
			return float3(-d.x * steepness * cosW, 0, -d.y * steepness * cosW);
		}

		float3 GetNormal(float2 xy)
		{
			float3 normal = float3(0, 1, 0);
			normal += _Steepness * dwave(xy, _Wave0);
			normal += _Steepness * dwave(xy, _Wave1);
			normal += _Steepness * dwave(xy, _Wave2);
			normal += _Steepness * dwave(xy, _Wave3);

			return normalize(normal);
		}

		void vert(inout appdata_full v) {
			v.vertex.xyz = GetPos(v.vertex.xyz, v.texcoord);
			v.normal  = GetNormal(v.texcoord);
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}