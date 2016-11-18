Shader "Hidden/Mistral/Flare"
{
	Properties
	{
		_MainTex ( "Base Texture (RGB) ", 2D ) = "white" {}
		_Flare ( "Flare Texture (RGB) - Warning: Generated during runtime! ", 2D ) = "black" {}
		_Gradient ( "Gradient Sample Texture (RGB)", 2D ) = "white" {} 
	}

	SubShader
	{
		///0 - DownSample
		Pass
		{
			CGPROGRAM

			#pragma vertex vert_DownSample
			#pragma fragment frag_DownSample

			ENDCG
		}

		///1 - Ghost
		Pass
		{
			CGPROGRAM

			#pragma vertex vert_Simple
			#pragma fragment frag_Ghost

			ENDCG
		}

		///2 - Blur Horizontally
		Pass
		{
			CGPROGRAM

			#pragma vertex vert_HorizontalBlur
			#pragma fragment frag_Blur

			ENDCG
		}

		///3 - Blur Vertically 
		Pass
		{
			CGPROGRAM

			#pragma vertex vert_VerticalBlur
			#pragma fragment frag_Blur

			ENDCG
		}

		///4 - Apply the Flare Texture to the final Result 
		Pass
		{
			CGPROGRAM

			#pragma vertex vert_Simple
			#pragma fragment frag_Flare

			ENDCG
		}
	}

	CGINCLUDE

	#include "UnityCG.cginc"

	///Samplers

	uniform sampler2D _MainTex;
	uniform sampler2D _Flare;
	uniform sampler2D _Gradient;

	///Samplers

	///SV

	uniform float4 _MainTex_ST;
	uniform float4 _MainTex_TexelSize;

	///SV

	///Flare Properties

	uniform float _Threshold;
	uniform float _Intensity;
	uniform float _GhostNum;
	uniform float _GhostDispersal;
	uniform float _HaloWidth;

	uniform fixed4 _ColorDistortion;

	///Flare Properties

	///Blur Properties

	uniform float _DownSampleValue;

	static const half4 GaussWeight[7] =  
    {  
        half4(0.0205,0.0205,0.0205,0),  
        half4(0.0855,0.0855,0.0855,0),  
        half4(0.232,0.232,0.232,0),  
        half4(0.324,0.324,0.324,1),  
        half4(0.232,0.232,0.232,0),  
        half4(0.0855,0.0855,0.0855,0),  
        half4(0.0205,0.0205,0.0205,0)  
    }; 

    ///Blur Properties

    ///Utilities

    fixed4 GetDistortedColor ( half2 uv, half2 dir)
    {
    	return fixed4 (
    		tex2D ( _MainTex, uv + dir * _ColorDistortion.r ).r,
    		tex2D ( _MainTex, uv + dir * _ColorDistortion.g ).g,
    		tex2D ( _MainTex, uv + dir * _ColorDistortion.b ).b,
    		1
    	);
    }

    ///Utilities

    ///DownSample 

	struct v2f_DownSample
	{
		float4 pos : SV_POSITION;
		half2 uv20 : TEXCOORD0;
		half2 uv21 : TEXCOORD1;
		half2 uv22 : TEXCOORD2;
		half2 uv23 : TEXCOORD3;
	};

	v2f_DownSample vert_DownSample ( appdata_img v )
	{
		v2f_DownSample o;

		o.pos = mul ( UNITY_MATRIX_MVP, v.vertex );

		o.uv20 = UnityStereoScreenSpaceUVAdjust ( v.texcoord + _MainTex_TexelSize * half2 ( 0.5h, 0.5h ), _MainTex_ST );
		o.uv21 = UnityStereoScreenSpaceUVAdjust ( v.texcoord + _MainTex_TexelSize * half2 ( -0.5h, 0.5h ), _MainTex_ST );
		o.uv22 = UnityStereoScreenSpaceUVAdjust ( v.texcoord + _MainTex_TexelSize * half2 ( -0.5h, -0.5h ), _MainTex_ST );
		o.uv23 = UnityStereoScreenSpaceUVAdjust ( v.texcoord + _MainTex_TexelSize * half2 ( 0.5h, -0.5h ), _MainTex_ST );

		return o;
	}

	fixed4 frag_DownSample ( v2f_DownSample i ) : COLOR
	{
		fixed4 color = tex2D ( _MainTex, i.uv20 ) + tex2D ( _MainTex, i.uv21 ) + tex2D ( _MainTex, i.uv22 ) + tex2D ( _MainTex, i.uv23 );
    	return max ( 0.0, color / 4 - _Threshold ) * _Intensity;
	}

	///DownSample

	struct v2f_Simple
	{
		float4 pos : SV_POSITION;
		half2 uv : TEXCOORD0;
	};

	///Ghost

	v2f_Simple vert_Simple ( appdata_img v )
	{
		v2f_Simple o;

		o.pos = mul ( UNITY_MATRIX_MVP, v.vertex );

		o.uv = v.texcoord.xy;

		return o;
	}

	fixed4 frag_Ghost ( v2f_Simple i ) : COLOR
	{
		half2 newUV = half2 ( 1.0h, 1.0h ) - i.uv;
		half2 ghostVector = ( half2 ( 0.5h, 0.5h ) - newUV ) * _GhostDispersal;
		fixed4 finalColor = fixed4 ( 0, 0, 0, 0 );
		for (int ii = 0;ii < _GhostNum;ii++)
		{
			half2 offset = frac ( newUV + ghostVector * float ( ii ) );
			float weight = length ( half2 ( 0.5h, 0.5h ) - offset ) / length ( half2 ( 0.5h, 0.5h ) );
      		weight = pow ( 1.0 - weight, 3.0 );
      		finalColor += GetDistortedColor ( offset, normalize ( ghostVector ) ) * weight;//tex2D ( _MainTex, offset ) * weight;
      		half2 haloVec = normalize ( ghostVector ) * _HaloWidth;
   			weight = length ( half2 ( 0.5h, 0.5h ) - frac ( newUV + haloVec ) ) / length ( half2 ( 0.5h, 0.5h ) );
   			weight = pow ( 1.0 - weight, 30.0 );
   			//finalColor += tex2D ( _MainTex, newUV + haloVec ) * weight;
		}
		return finalColor * tex2D ( _Gradient, length ( half2 ( 0.5h, 0.5h ) - newUV ) / length ( half2 ( 0.5h, 0.5h ) ) );
	}

	///Ghost

	///Blur

	struct v2f_Blur 
	{
		float4 pos : SV_POSITION;
		half2 uv : TEXCOORD0;
		half2 offset : TEXCOORD1;
	};

	v2f_Blur vert_HorizontalBlur ( appdata_img v )
	{
		v2f_Blur o;

		o.pos = mul ( UNITY_MATRIX_MVP, v.vertex );

		o.uv = v.texcoord.xy;

		o.offset = _MainTex_TexelSize * _DownSampleValue * half2 ( 1.0h, 0.0h );

		return o;
	}

	v2f_Blur vert_VerticalBlur ( appdata_img v )
	{
		v2f_Blur o;

		o.pos = mul ( UNITY_MATRIX_MVP, v.vertex );

		o.uv = v.texcoord.xy;

		o.offset = _MainTex_TexelSize * _DownSampleValue * half2 ( 0.0h, 1.0h );

		return o;
	}

	fixed4 frag_Blur ( v2f_Blur i ) : COLOR
	{
		half2 currentUV = i.uv - i.offset * 3;
		fixed4 finalColor = fixed4 ( 0, 0, 0, 0 );
		for (int ii = 0;ii < 7;ii++)
		{
			finalColor += tex2D ( _MainTex, currentUV ) * GaussWeight[ii];
			currentUV += i.offset;
		}
		return finalColor;
	}

	///Blur

	///Flare

	fixed4 frag_Flare ( v2f_Simple i ) : COLOR
	{
		return tex2D ( _MainTex, i.uv ) + tex2D ( _Flare, i.uv );
	}

	///Flare

	ENDCG
}
