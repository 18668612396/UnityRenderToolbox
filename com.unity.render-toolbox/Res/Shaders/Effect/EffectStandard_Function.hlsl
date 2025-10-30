#ifndef EFFECT_STANDARD_FUNCTION_INCLUDED
#define EFFECT_STANDARD_FUNCTION_INCLUDED

// 旋转纹理UV坐标
// 参数:
//   uv: 原始纹理坐标
//   rotationParams: 旋转参数 (x: cosθ, y: sinθ, z: 旋转后X偏移, w: 旋转后Y偏移)
// 返回: 旋转后的UV坐标
float2 RotateTextureUV(float2 uv, float4 rotationParams)
{
    return float2(
        dot(uv, float2(rotationParams.x, rotationParams.y)) + rotationParams.z,
        dot(uv, float2(-rotationParams.y, rotationParams.x)) + rotationParams.w
    );
}

// 应用UV动画效果
// 参数:
//   animationSource: 动画源类型 (1: custom01数据, 2: custom02数据, 3: 时间驱动动画)
//   custom01: 自定义数据通道1
//   channel01: 自定义数据X通道索引
//   custom02: 自定义数据通道2
//   channel02: 自定义数据Y通道索引
//   _ST: 纹理缩放偏移参数 (xy: 缩放, zw: 动画速度)
// 返回: 计算后的UV动画偏移量
float2 ApplyUVAnimation(
    int animationSource, 
    half4 custom01, 
    int channel01, 
    half4 custom02, 
    int channel02, 
    float4 _ST = float4(1, 1, 0, 0)
)
{
    float2 mainAnimation = 0;

    // 从custom01通道获取动画偏移
    if (animationSource == 1)
    {
        mainAnimation = float2(
            custom01[channel01 - 1], 
            custom01[channel02 - 1]
        );
    }
    // 从custom02通道获取动画偏移
    else if (animationSource == 2)
    {
        mainAnimation = float2(
            custom02[channel01 - 1], 
            custom02[channel02 - 1]
        );
    }
    // 时间驱动的自动UV动画
    else if (animationSource == 3)
    {
        // 以下为备选实现: 将UV限制在[-1,1]范围，实现完整流动效果
        // 适用于CLAMP模式纹理，可从一侧完整流动到另一侧
        // float2 speed = _ST.zw * min(float2(channel01, channel02), 1);
        // float2 result = sign(speed) * (frac(_Time.y * abs(speed)) * 2.0 - 1.0) * _ST.xy;
        // mainAnimation = result;

        // 当前实现: 基于时间的循环UV偏移（适用于REPEAT模式纹理）
        mainAnimation = frac(_ST.zw * _Time.y) * min(float2(channel01, channel02), 1);
    }

    return mainAnimation;
}

// 计算溶解效果因子
// 参数:
//   noise: 噪声纹理采样值
//   threshold: 溶解阈值（控制溶解程度）
//   feather: 边缘软化程度（值越大边缘越模糊）
// 返回: 溶解因子（0~1，0表示完全溶解，1表示完全显示）
float GetDissolveFactor(float noise, float threshold, float feather)
{
    // 计算软化区间
    float base = lerp(0 - feather, 1 + feather, threshold);
    float sMin = base - feather;  // 软化区间最小值
    float sMax = base + feather;  // 软化区间最大值
    
    // 计算平滑过渡因子
    float sFactor = smoothstep(sMin, sMax, noise);
    return sFactor;
}

// 应用流动扭曲效果到UV
// 参数:
//   uv: 原始UV坐标
//   DistortionVector: 流动方向向量
//   intensity: 扭曲强度
// 返回: 扭曲后的UV坐标
float2 ApplyDistortion(float2 uv, float2 distortionVector, float intensity)
{
    return uv + distortionVector * intensity;
}

#endif