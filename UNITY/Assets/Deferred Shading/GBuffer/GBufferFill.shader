﻿Shader "Hidden/G-BufferFill" {
    Properties 
    {
        _MainTex ("Albedo (sRGB)", 2D) = "black" {}
        _NormalTexture ("Normal Map (sRGB)", 2D) = "gray" {}
        _SpecularColor ("Specular Color (sRGB)", 2D) = "blue" {}
        _Roughness ("Roughness (Linear)", 2D) = "green" {}
        _DepthTexture ("Depth (Linear)", 2D) = "white" {}
    }

    SubShader 
    {
        Tags { "GBuffer"="Opaque" }
        
        Pass
        {
            ZTest LEQual Cull Back ZWrite On
            Fog { Mode off }

            CGPROGRAM
            #pragma exclude_renderers gles
            #pragma vertex vert 
            #pragma fragment frag
            #pragma target 3.0
            #include "UnityCG.cginc"
            #include "GBufferUtilities.cginc"

            uniform sampler2D _MainTex;
            uniform sampler2D _SpecularColor;
            uniform sampler2D _Roughness;
            uniform sampler2D _NormalTexture;
            uniform sampler2D _DepthTexture;

            struct vertexInput
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct vertexOutput  
            {
                float4 pos : SV_POSITION;
                float2 tex : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float depth : TEXCOORD3;
            };

            struct PixelOutput
            {
                float4 Albedo : COLOR0; // Albedo (RGB) MatIDs (A)
                float4 Normal : COLOR1; // Normal (RG) Depth (BA)
                float4 Spec : COLOR2; //  Specular Color (RGB)  Roughness(A)
            };

            vertexOutput vert( vertexInput v ) 
            {
                vertexOutput output;
 
                float4x4 modelMatrix = _Object2World;
                float4 pos = mul( UNITY_MATRIX_MVP, v.vertex );

                output.normal = COMPUTE_VIEW_NORMAL;
                output.tex = TRANSFORM_UV(0);
                output.pos = pos;
                output.depth = (pos.z / pos.w);

                return output;
            }
            
            PixelOutput PackGBuffer(float roughness, float MatID, float2 coords, float3 normal, float depth, out PixelOutput output)
            {
                // ---------------------BUFFER I---------------------
                //Albedo
                float3 Albedo = tex2D( _MainTex, coords );
                output.Albedo.rgb = Albedo;
                //Material ID
                output.Albedo.a = MatID.x;
                // ---------------------BUFFER II---------------------
                //Normals
                output.Normal.rg = EncodeSphereNormals( normal );
				
                output.Normal.ba = EncodeDepth(depth);
                // ---------------------BUFFER III---------------------
                //Colored Spec
                float3 Specular = tex2D( _SpecularColor, coords );
                output.Spec.rgb = Specular;
                // Roughness
                float rough = tex2D(_Roughness, coords).x;
                output.Spec.a = roughness * rough;
				// ---------------------BUFFER IV----------------------
                
                return output;
            }
 
            PixelOutput frag( vertexOutput input ) 
            {   
                PixelOutput output;
            
                float roughness;
                float MatID;
                
                float3 normal = input.normal;
                float2 coords = input.tex;
                float depth = input.depth;
                
                return PackGBuffer(roughness, MatID, coords, normal, depth, output);
            }

            ENDCG
        }
    }
}