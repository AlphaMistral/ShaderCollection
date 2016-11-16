Shader "Hidden/Mistral/BlurMobile"
{
	Properties
	{
		_MainTex ( "Base Texture (RGB)", 2D ) = "white" {}
	}

	SubShader
	{
		///Pass 0, DownSamples the Texture. Theoritically the texture is reduced by 3 times. 
		Pass
		{
			CGPROGRAM

			#pragma vertex vert_DownSample
			#pragma fragment frag_DownSample

			ENDCG
		}

		///Pass 1, Blurs Horiontally
		Pass
		{
			CGPROGRAM

			#pragma vertex vert_HorizontalBlur
			#pragma fragment frag_Blur

			ENDCG
		}

		Pass
		{
			CGPROGRAM

			#pragma vertex vert_VerticalBlur
			#pragma fragment frag_Blur

			ENDCG
		}
	}

	CGINCLUDE

	#include "UnityCG.cginc"

	uniform sampler2D _MainTex;
	uniform half4 _MainTex_TexelSize;
	uniform half4 _MainTex_ST;
	uniform half _DownSampleValue;

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

    ///Area DownSample

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

    	o.pos = mul ( UNITY_MATRIX_MVP, v.vertex);
    	o.uv20 = UnityStereoScreenSpaceUVAdjust ( v.texcoord + _MainTex_TexelSize.xy * half2 ( 0.5h, 0.5h ), _MainTex_ST );
    	o.uv21 = UnityStereoScreenSpaceUVAdjust ( v.texcoord + _MainTex_TexelSize.xy * half2 ( -0.5h, 0.5h ), _MainTex_ST );
    	o.uv22 = UnityStereoScreenSpaceUVAdjust ( v.texcoord + _MainTex_TexelSize.xy * half2 ( -0.5h, -0.5h ), _MainTex_ST );
    	o.uv23 = UnityStereoScreenSpaceUVAdjust ( v.texcoord + _MainTex_TexelSize.xy * half2 ( 0.5h, -0.5h ), _MainTex_ST );

    	return o;
    }

    fixed4 frag_DownSample ( v2f_DownSample i ) : COLOR
    {
    	fixed4 color = tex2D ( _MainTex, i.uv20 ) + tex2D ( _MainTex, i.uv21 ) + tex2D ( _MainTex, i.uv22 ) + tex2D ( _MainTex, i.uv23 );
    	color /= 4;
    	return color;
    }

    ///Area DownSample

    ///Area Blur

    struct v2f_Blur 
    {
    	float4 pos : SV_POSITION;
    	half4 uv : TEXCOORD0;
    	half2 offset : TEXCOORD1;
    };

    v2f_Blur vert_HorizontalBlur ( appdata_img v )
    {
    	v2f_Blur o;

    	o.pos = mul ( UNITY_MATRIX_MVP, v.vertex );

    	o.uv = half4 ( v.texcoord.xy, 1, 1);

    	o.offset = _MainTex_TexelSize.xy * half2 ( 1.0, 0.0 ) * _DownSampleValue;

    	return o;
    }

    v2f_Blur vert_VerticalBlur ( appdata_img v )
    {
    	v2f_Blur o;

    	o.pos = mul ( UNITY_MATRIX_MVP, v.vertex );

    	o.uv = half4 ( v.texcoord.xy, 1, 1);

    	o.offset = _MainTex_TexelSize.xy * half2 ( 0.0, 1.0 ) * _DownSampleValue;

    	return o;
    }

    fixed4 frag_Blur ( v2f_Blur i ) : COLOR
    {
    	half2 uv = i.uv.xy;
    	half2 offset = i.offset.xy;
    	half2 currentUV = uv - offset * 3;
    	half4 finalColor = 0;
    	for (int ii = 0;ii < 7;ii++)
    	{
    		finalColor += tex2D ( _MainTex, currentUV ) * GaussWeight[ii];
    		currentUV += offset;
    	}
    	return finalColor;
    }

    ///Area Blur

	ENDCG
}