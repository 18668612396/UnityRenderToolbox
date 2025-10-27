Shader "Custom/UnrealEyePupil"
{
    Properties
    {
        [Header(Textures)]
        _NormalTex ("Normal Map (Texture2D_0)", 2D) = "bump" {}  // Unreal中的Texture2D_0，法线贴图
        _CausticTex ("Caustic/Iris Texture (Texture2D_1)", 2D) = "white" {}  // Unreal中的Texture2D_1
        _PupilTex ("Pupil Texture (Texture2D_2)", 2D) = "white" {}  // Unreal中的Texture2D_2，瞳孔纹理

        [Header(Scalar Parameters)]
        _InternalIoR ("Internal IoR", Float) = 1.4  // 假设眼睛内部IoR
        _IrisScale ("Iris Scale", Float) = 1.0
        _Intensity ("Intensity", Float) = 1.0
        _Offset ("Offset", Float) = 0.0
        _Scale ("Scale", Float) = 1.0
        _PupilScale ("Pupil Scale", Float) = 1.0
        _LerpAmount ("Lerp Amount", Range(0,1)) = 0.0

        [Header(Vector Parameters)]
        _CausticUV ("Caustic UV", Vector) = (0.5, 0.5, 0, 0)
        _ParallaxHeight ("Parallax Height", Vector) = (1, 1, 0, 0)
        _LerpColor ("Lerp Color", Color) = (0, 0, 0, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldTangent : TEXCOORD2;
                float3 worldBitangent : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
                float3 viewDir : TEXCOORD5;
            };

            sampler2D _NormalTex;
            sampler2D _CausticTex;
            sampler2D _PupilTex;

            float _InternalIoR;
            float _IrisScale;
            float _Intensity;
            float _Offset;
            float _Scale;
            float _PupilScale;
            float _LerpAmount;
            float2 _CausticUV;
            float2 _ParallaxHeight;
            float3 _LerpColor;

            // CustomExpression0: 计算折射向量
            float3 CustomExpression0(float internalIoR, float3 normalW, float3 cameraW)
            {
                float airIoR = 1.00029;
                float n = airIoR / internalIoR;
                float facing = dot(normalW, cameraW);
                float w = n * facing;
                float k = sqrt(1 + (w - n) * (w + n));
                float3 t = (w - k) * normalW - n * cameraW;
                t = normalize(t);
                return -t;
            }

            // CustomExpression1: 瞳孔UV缩放
            float2 CustomExpression1(float2 UV, float PupilScale)
            {
                float2 UVcentered = UV - float2(0.5f, 0.5f);
                float UVlength = length(UVcentered);
                float2 UVmax = normalize(UVcentered) * 0.5f;
                float2 UVscaled = lerp(UVmax, float2(0.f, 0.f), saturate((1.f - UVlength * 2.f) * PupilScale));
                return UVscaled + float2(0.5f, 0.5f);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                // 计算TBN矩阵
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                o.worldBitangent = cross(o.worldNormal, o.worldTangent) * tangentSign;

                o.viewDir = normalize(_WorldSpaceCameraPos - o.worldPos);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;

                // 采样法线贴图并转换为世界空间
                float4 normalMap = tex2D(_NormalTex, uv);
                float3 tangentNormal = UnpackNormal(normalMap);
                float3x3 TBN = float3x3(normalize(i.worldTangent), normalize(i.worldBitangent), normalize(i.worldNormal));
                float3 worldNormal = mul(tangentNormal, TBN);
                // Local0: 假设切线向量为(1,0,0)在世界空间
                float3 Local0 = i.worldTangent;
                float Local1 = dot(Local0, Local0);
                float Local2 = sqrt(Local1);
                float3 Local3 = Local0 / Local2;

                // Local7: 世界法线
                float3 Local7 = worldNormal;

                float Local8 = dot(Local3, Local7);
                float3 Local9 = Local8 * Local7;
                float3 Local10 = Local3 - Local9;
                float Local11 = dot(Local10, Local10);
                float Local12 = sqrt(Local11);
                float3 Local13 = Local10 / Local12;

                // 计算折射向量，使用世界法线和相机向量
                float3 cameraVector = -i.viewDir;  // Unreal中的Parameters.CameraVector = normalize(-WorldPosition_CamRelative)
                float3 Local14 = CustomExpression0(_InternalIoR, i.worldNormal, cameraVector);  // 使用顶点法线或扰动法线？Unreal用Parameters.WorldNormal，这里用i.worldNormal作为基础

                // 采样Caustic纹理
                float4 Local16 = tex2D(_CausticTex, uv);
                float4 Local19 = tex2D(_CausticTex, _CausticUV.xy);

                float3 Local21 = Local16.rgb - Local19.r;
                float3 Local22 = max(Local21, float3(0,0,0));
                float3 Local23 = Local22 * _Intensity;

                float Local24 = dot(cameraVector, Local7);
                float Local25 = Local24 * Local24;
                float Local26 = lerp(0.325, 1.0, Local25);

                float3 Local27 = Local23 / Local26;
                float3 Local28 = Local14 * Local27;

                float Local29 = dot(Local13, Local28);
                float3 Local30 = cross(Local13, Local7);
                float Local31 = dot(Local30, Local28);

                float2 Local32 = _ParallaxHeight * float2(Local29, Local31);

                float2 Local33 = uv / _IrisScale;
                float2 Local34 = Local33 + 0.5;
                float2 Local35 = Local34 - _Offset;
                float2 Local36 = Local32 + Local35;
                float2 Local37 = Local36 - 0.5;
                float2 Local38 = Local37 * _Scale;
                float2 Local39 = Local38 + 0.5;

                float2 Local40 = CustomExpression1(Local39, _PupilScale);

                float4 Local42 = tex2D(_PupilTex, Local40);

                float3 Local44 = lerp(Local42.rgb, _LerpColor, _LerpAmount);

                return fixed4(Local44, 1.0);
            }
            ENDCG
        }
    }
}