// http://espressomd.org/html/doc/electrostatics.html#debye-huckel-potential
// http://espressomd.org/html/doc/electrostatics.html#equation-coulomb-prefactor

// https://www.sciencedirect.com/topics/chemistry/electrostatic-interactions
// https://www.sciencedirect.com/topics/chemistry/monte-carlo-method
// https://www.sciencedirect.com/topics/chemistry/molecular-dynamics

// https://towardsdatascience.com/a-simple-monte-carlo-simulation-to-solve-a-putnam-competition-math-problem-28545df6562d


import std.math;
import std.stdio;
import core.stdc.signal;

import Particle;
import ParticleSpec;
import Playground;

bool interruptDetected = false;

extern(C) void interruptHandler(int sig) nothrow @nogc @system
{
    interruptDetected = true;
}

class Simulation
{
    /*
    https://en.wikipedia.org/wiki/Atomic_radius
    Radius of Hyrogen is 53pm, Helium is 31pm.
    Biggest radius with 298pm is Caesium.
    */
    public immutable double RADIUS_HYDROGEN = 53;  // H+
    public immutable double RADIUS_OXYGEN = 48;  // O-2

    private Playground playground;

    private double C;
    private double r_cut;
    private double kappa;

    private ParticleSpec hydrogenSpec;
    private ParticleSpec oxygenSpec;

    public this(
        double boxHeight,
        double minimumInitialDistance,
        size_t totalNumberOfH,
        size_t totalNumberOfO,
        double topWallCharge,
        double bottomWallCharge
    )
    {
        C = 1;
        r_cut = 6000;   // picometer
        kappa = 0.05;

        hydrogenSpec = new ParticleSpec( RADIUS_HYDROGEN, +1, "H" );
        oxygenSpec = new ParticleSpec( RADIUS_OXYGEN, -2, "O" );

        write("Initialising the playground ... ");
        playground =
            new Playground(
                boxHeight,
                minimumInitialDistance,
                topWallCharge,
                bottomWallCharge
            );

        playground.addParticles( hydrogenSpec, totalNumberOfH );
        playground.addParticles( oxygenSpec, totalNumberOfO );

        writeln("OK");
    }

    private double calculateTotalPotential()
    {
        double U = 0;

        for(auto i1=0; i1 < playground.numOfParticles; ++i1)
        {
            Particle particle1 = playground.particle( i1 );

            // potential with walls. straight distance in Y direction.
            U += DH( C, particle1.spec.q, playground.topWallCharge, kappa, std.math.abs(playground.boxTop - particle1.y), r_cut );
            U += DH( C, particle1.spec.q, playground.bottomWallCharge, kappa, std.math.abs(particle1.y - playground.boxBottom), r_cut );

            // potential with other particles
            for(auto i2=i1+1; i2 < playground.numOfParticles; ++i2)
            {
                Particle particle2 = playground.particle( i2 );

                U += DH( particle1, particle2 );
            }

        }

        return U;
    }

    /**
     * Debye-Hückel potential
     *
     * Params:
     * C = Electrostatics prefactor. Coulomb.
     * q1 = Charge of particle 1
     * q2 = Charge of particle 2
     * kappa = Inverse Debye screening length
     * r = Distance between charges
     * r_cut = Cut off radius for this interaction. After this distance, the result will be zero always.
     *
     * Returns: Calculated potential
     */
    public double DH( double C, double q1, double q2, double kappa, double r, double r_cut )
    {
        if( r > r_cut )
        {
            return 0;
        }
        else
        {
            return (C * q1 * q2 * std.math.exp( -1*kappa * r )) / r;
        }
    }

    private double DH( Particle particle1, Particle particle2 )
    {
        return DH( C, particle1.spec.q, particle2.spec.q, kappa, particle1.distanceTo( particle2 ), r_cut );
    }

    public void run()
    {
        Particle movedParticle;
        double prevTotalPotential;
        double currentTotalPotential;
        double minTotalPotential;
        double maxTotalPotential;
        double allowedMaxTotalPotential;

        currentTotalPotential = calculateTotalPotential();

        prevTotalPotential = currentTotalPotential;
        minTotalPotential = currentTotalPotential;
        maxTotalPotential = currentTotalPotential;


        writeln("Initial total potential of the system is ", currentTotalPotential );

        writeln("Simulation has started running!");

        for(auto i=0, c=60*2000; (i < c) && (!interruptDetected); ++i)
        {
            allowedMaxTotalPotential = prevTotalPotential;

            // we allow the total potential to be increased a little bit to be able to overcome the local minimum.
            allowedMaxTotalPotential = minTotalPotential + abs(minTotalPotential * 0);

            if( allowedMaxTotalPotential > maxTotalPotential ){ allowedMaxTotalPotential = maxTotalPotential; }

            //-----

            write( i, " / ", c , ": Moving a particle ... ");

            // until we move a particle in the right direction so the total potential of system does not decrease,
            // we should continue the search.
            while( true )
            {
                movedParticle = playground.moveOneParticle( 10 );

                currentTotalPotential = calculateTotalPotential();

                if( currentTotalPotential > allowedMaxTotalPotential )
                {
                    movedParticle.restorePosition();
                }
                else{
                    prevTotalPotential = currentTotalPotential;
                    break;
                }
            }

            writeln("OK");
            writeln("Current system potential is ", currentTotalPotential);
            writeln();

            if( minTotalPotential > currentTotalPotential ){ minTotalPotential = currentTotalPotential; }
        }

        writeln("Simulation completed!");
    }
}

void main()
{
    core.stdc.signal.signal( SIGINT, &interruptHandler );

    Simulation sim = new Simulation( 4000, 200, 100, 100, 0, -0 );

    sim.run( );
}

