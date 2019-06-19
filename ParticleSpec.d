class ParticleSpec
{
	private double _r;
	private double _q;
	private string _type;

	public this( double r, double q, string type )
	{
		_r = r;
		_q = q;
		_type = type;
	}

    public double r(){ return _r; }
    public double q(){ return _q; }
    public string type(){ return _type; }
}
