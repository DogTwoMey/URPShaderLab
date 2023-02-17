Shader "TestShader1"
{
    Properties
    {
        //变量名 UI显示中的名称 类型 赋值 
        _Color("Color",color) = (1,1,0,1)
        _BaseMap("Base Map",2D) = "white"{}
        _Shininess("Shininess",float) = 32
        _NormalMap("Normal Map",2D) ="bump"{}
    }

    SubShader
    {

        Pass        
        {
            HLSLPROGRAM

            #pragma vertex Vertex
            #pragma fragment Pixel 
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            half4 _Color;
            sampler2D _BaseMap;
            half _Shininess;
            sampler2D _NormalMap;

            struct Attributes{
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct Varyings{
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : NORMAL;
                float3 positionWS : TEXCOORD1;
                float4 tangentWS : TANGENT; 
            };
            
            Varyings Vertex(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.vertex.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normal);
                OUT.positionWS = mul(UNITY_MATRIX_M,float4(IN.vertex.xyz,1.0));
                OUT.uv = IN.uv;
                OUT.tangentWS.xyz=TransformObjectToWorldDir(IN.tangent).xyz;
                OUT.tangentWS.w=IN.tangent.w;
                return OUT;
            }
            
            half4 Pixel(Varyings IN) : SV_TARGET
            {
                half4 OUT;
                Light light = GetMainLight();
                float3 bitangent = cross(IN.normalWS,IN.tangentWS);
                float3x3 TBN = float3x3(IN.tangentWS.xyz,bitangent,IN.normalWS);
                
                float3 normal = UnpackNormal(tex2D(_NormalMap,IN.uv));
                float3 WorldspaceNormal = TransformTangentToWorld(normal,TBN);
                
                float3 viewDir = -normalize(-_WorldSpaceCameraPos.xyz + IN.positionWS);
                float3 reflDir = reflect(light.direction,normalize(WorldspaceNormal));
                float3 hVec = normalize(viewDir + light.direction);
                float NoL = max(0, dot(WorldspaceNormal,light.direction));
                // float spec = max(0,dot(viewDir,reflDir)); //Phong
                float spec = max(0,dot(normalize(WorldspaceNormal),hVec)); //Blinn-Phong
                spec = pow(spec,_Shininess);

                half3 gi = SampleSH(IN.normalWS) * 0.02;
                // 球谐函数 通过法线信息，采样环境中的低频信息
                // 在兰伯特光照模型中可以直接加

                OUT.rgb = tex2D(_BaseMap,IN.uv).rgb * _Color * NoL * light.color + gi + spec;
                OUT.a = 1.0;
                return OUT;
            }

            ENDHLSL
        }
    }
}