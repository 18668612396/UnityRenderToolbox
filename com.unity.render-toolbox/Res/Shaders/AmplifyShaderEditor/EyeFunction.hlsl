float2 RefractionDirection(float internalIoR, float3 normalW, float3 cameraW)
{
    float airIoR = 1.00029;

    float n = airIoR / internalIoR;

    float facing = dot(normalW, cameraW);

    float w = n * facing;

    float k = sqrt(1+(w-n)*(w+n));

    float3 t;
    t = (w - k)*normalW - n*cameraW;
    t = normalize(t);
    return -t.xy;
}