import Particle;
import ParticleSpec;

import std.random;
import std.math;
import std.stdio;

class Playground
{
    private Particle[] particles;
    private size_t n;

    private immutable double _boxHeight;
    private immutable double _boxTop;
    private immutable double _boxBottom;

    private immutable double _topWallCharge;
    private immutable double _bottomWallCharge;

    private double _minimumInitialDistance;

    /**
     * Params:
     * boxHeight = Height of the boundary box in picometer
     * minimumInitialDistance = When all particles are created initially, what should be the minimum distance between each and every particles' center in picometer.
     * totalNumberOfH = Total number of Hydrogen particles to be created.
     * totalNumberOfO = Total number of Oxygen particles to be created.
     */
    public this(
    	double boxHeight,
    	double minimumInitialDistance,
    	double topWallCharge,
    	double bottomWallCharge
    )
    {
        _minimumInitialDistance = minimumInitialDistance;

        particles = new Particle[0];

    	n = 0;

	    // box has a single boundary and it is in Y direction.
	    // in other directions (X and Z), box is accepted as infinite.
	    // center of the box is accepted as X=0, Y=0, Z=0
    	_boxHeight = boxHeight;
    	_boxTop = boxHeight / 2.0;
    	_boxBottom = -1*_boxTop;

    	_topWallCharge = topWallCharge;
    	_bottomWallCharge = bottomWallCharge;
    }

    public double boxHeight() const pure{ return _boxHeight; }
    public double boxTop() const pure{ return _boxTop; }
    public double boxBottom() const pure{ return _boxBottom; }

    public double topWallCharge() const pure{ return _topWallCharge; }
    public double bottomWallCharge() const pure{ return _bottomWallCharge; }

    public auto addParticles( ParticleSpec spec, size_t num )
    {
        for(auto i=0; i < num; ++i)
        {
            auto particle = new Particle( 0, 0, 0, spec );

            particles ~= particle;

            moveParticleToAnAcceptablePosition( n );

            ++n;
        }

        return this;
    }

    private void moveParticleToAnAcceptablePosition( size_t particleIndex )
    {
        auto p1 = particles[ particleIndex ];

        while( !isParticlePositionAcceptable( particleIndex, _minimumInitialDistance ) )
        {
            p1.savePosition();

            moveParticleRandomly( particleIndex, _minimumInitialDistance * 10 );

            if( !isParticleInBoundaries( particleIndex ) )
            {
                p1.restorePosition();
            }
        }
    }

    public Particle particle( const size_t index ) pure{ return ( index >= n ) ? null : particles[ index ]; }

    public size_t numOfParticles() const pure{ return n; }

    /**
     * This method is used for the random movement operation of the Monte Carlo method.
     *
     * Params:
     * delta = How many picometers to move the particle in any dimension.
     *
     * Return: The moved particle
     */
    public Particle moveOneParticle( double delta )
    {
    	Particle particle;
    	size_t particleIndex;
    	int movementX, movementY, movementZ;

    	// until being able to move a particle without causing overlap, continue the search.
    	while( true )
    	{
	    	particleIndex = std.random.uniform!"[)"( 0, n );

            particle = particles[ particleIndex ];

            // in case the following movement causes an overlap, we can go back to previous position
            particle.savePosition();

	    	moveParticleRandomly( particleIndex, delta );

	    	// check overlap with other particles, also with the box.
	    	if( isParticlePositionAcceptable( particleIndex ) )
	    	{
	    		// we moved the particle randomly, and its latest position is acceptable.
	    		return particle;
	    	}

	    	// cannot move the particle to there
	    	else{
	    		particle.restorePosition();
	    	}
	    }
    }

    private bool isParticleInBoundaries( size_t particleIndex, double minDistanceFromWalls=0 )
    {
        auto particle = particles[ particleIndex ];

        if( minDistanceFromWalls < 0 ){ minDistanceFromWalls = 0; }

        // we have boundaries in Y direction only
        if( (_boxTop - (particle.y + particle.spec.r)) < minDistanceFromWalls ){ return false; }
        if( ((particle.y - particle.spec.r) - _boxBottom) < minDistanceFromWalls ){ return false; }

        return true;
    }

    private bool isParticlePositionAcceptable( size_t particleIndex, double minimumAcceptableDistance=0 )
    {
    	auto particle = particles[ particleIndex ];

    	// check whether the top side of the particle touches, outside of, or overlaps with the top wall of the box.
    	if( (particle.y + particle.spec.r) >= _boxTop ){ return false; }

    	// check whether the bottom side of the particle touches, outside of, or overlaps with the bottom wall of the box.
    	if( (particle.y - particle.spec.r) <= _boxBottom ){ return false; }

    	// check with other particles
    	for(auto i=0; i < n; ++i)
    	{
    		// do not compare with itself.
    		if( i == particleIndex ){ continue; }

    		// get the other particle
    		auto otherParticle = particles[ i ];

    		// check whether given particle and the other chose particle overlap.
    		if( particle.tooClose( otherParticle, minimumAcceptableDistance ) ){ return false; }
    	}

    	// it is okay in its current position.
    	return true;
    }

    private void moveParticleRandomly( size_t particleIndex, double delta )
    {
        delta = std.math.abs( delta );
        double delta_neg = -1 * delta;

        // whether to move in a dimension is a random decision due to Monte Carlo method
        // if value is 0, there wouldn't be any movement in that dimension.
        auto movementX = std.random.uniform!"[]"( delta_neg, delta );
        auto movementY = std.random.uniform!"[]"( delta_neg, delta );
        auto movementZ = std.random.uniform!"[]"( delta_neg, delta );

        auto particle = particles[ particleIndex ];

        // move
        particle.moveX( movementX );
        particle.moveY( movementY );
        //particle.moveZ( movementZ );   // I do not want Z (depth) due to visulisation problem
    }
}
