using System;

namespace UnityEngine.Rendering.HighDefinition
{
    [Serializable, VolumeComponentMenu("Post-processing/DCTArtifacts")]
    public sealed class DCTArtifacts : CustomPostProcessVolumeComponent, IPostProcessComponent
    {
        public BoolParameter enable = new BoolParameter(false, true);

        [Tooltip("Controls the intensity of the effect.")]
        public ClampedIntParameter level = new ClampedIntParameter(0, 1, 128, true);

        private Material m_Material = null;

        public bool IsActive()
        {
            return m_Material != null && level.value > 0f && enable.value;
        }

        public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

        public override void Setup()
        {
            if (Shader.Find("Hidden/Shader/DCTArtifacts") != null)
            {
                m_Material = new Material(Shader.Find("Hidden/Shader/DCTArtifacts"));
            }
        }

        public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
        {
            if (!enable.value || m_Material == null)
            {
                return;
            }

            m_Material.SetInteger("_Level", level.value);

            int DCT = Shader.PropertyToID("_MainTex");
            cmd.GetTemporaryRTArray(DCT, source.referenceSize.x, source.referenceSize.y, 0, 0, FilterMode.Point, Experimental.Rendering.GraphicsFormat.R16G16B16A16_SFloat);
            cmd.Blit(source, DCT, m_Material, 0);
            cmd.Blit(DCT, destination, m_Material, 1);
            cmd.ReleaseTemporaryRT(DCT);
        }

        public override void Cleanup()
        {
            CoreUtils.Destroy(m_Material);
        }
    }
}