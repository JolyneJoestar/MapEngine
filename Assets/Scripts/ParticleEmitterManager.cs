using System.Collections.Generic;
using System.Threading;
using UnityEngine;
using UnityEngine.Rendering;


public class ParticleEmitterManager
{
    private static ParticleEmitterManager m_instance = null;
    public Material particleMaterial { get; set; }
    List<ParticleEmitter> particleEmitters = new List<ParticleEmitter>();
    public void add(ParticleEmitter emitter)
    {
        particleEmitters.Add(emitter);
    }
    public void remove(ParticleEmitter emiiter)
    {
        particleEmitters.Remove(emiiter);
    }
    public void render(CommandBuffer commadnBuffer, ScriptableRenderContext contex, Camera camera)
    {
        foreach(var emitter in particleEmitters)
        {
            emitter.RenderParticles(commadnBuffer, contex, camera);
        }
    }

    private ParticleEmitterManager() { }
    public static ParticleEmitterManager Instance
    {
        get
        {
            if(m_instance == null)
            {
                m_instance = new ParticleEmitterManager();
            }
            return m_instance;
        }
    }
}
