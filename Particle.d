import std.math;
import std.conv;

import ParticlePosition;
import ParticleSpec;

class Particle
{
    private ParticleSpec _spec;

    private double _x, _y, _z;

    private double x_saved, y_saved, z_saved;


    public this( double x, double y, double z, ParticleSpec spec )
    {
        x_saved = _x = x;
        y_saved = _y = y;
        z_saved = _z = z;

        _spec = spec;
    }

    public double x(){ return _x; }
    public double y(){ return _y; }
    public double z(){ return _z; }

    public ParticleSpec spec(){ return _spec; }

    /**
     * Calculates pythagorian distance between this and other particle
     *
     * Returns: Distance
     */
    public double distanceTo( Particle otherParticle )
    {
        return
            std.math.sqrt(
                std.math.pow( _x - otherParticle._x, 2 ) +
                std.math.pow( _y - otherParticle._y, 2 ) +
                std.math.pow( _z - otherParticle._z, 2 )
            );
    }

    public bool overlaps( Particle otherParticle ){ return overlaps( this, otherParticle ); }

    public static bool overlaps( Particle particle1, Particle particle2 ){ return tooClose( particle1, particle2 ); }

    public bool tooClose( Particle otherParticle, double minDistance=0 ){ return tooClose( this, otherParticle, minDistance ); }

    public static bool tooClose( Particle particle1, Particle particle2, double minDistance=0 )
    {
        double distance = particle1.distanceTo( particle2 );

        double hardSphereMinDistance = (particle1.spec.r + particle2.spec.r);

        if( minDistance < hardSphereMinDistance ){ minDistance = hardSphereMinDistance; }

        return (distance < minDistance);   
    }

    public void savePosition()
    {
        x_saved = _x;
        y_saved = _y;
        z_saved = _z;
    }

    public void restorePosition()
    {
        _x = x_saved;
        _y = y_saved;
        _z = z_saved;
    }

    public auto moveX( double delta )
    {
        _x += delta;
        return this;
    }

    public auto moveY( double delta )
    {
        _y += delta;
        return this;
    }

    public auto moveZ( double delta )
    {
        _z += delta;
        return this;
    }

    public auto moveTo( double x, double y, double z )
    {
        _x = x;
        _y = y;
        _z = z;
        return this;
    }

    public string positionToJson()
    {
        return `[` ~ std.conv.to!string( _x ) ~ `,` ~ std.conv.to!string( _y ) ~ `,` ~ std.conv.to!string( _z ) ~ `]`;
    }
}
