float floor(float v,int n,int|void m)
{
	m=m||10;
	return predef::floor(v*pow(m,n))/pow(m,n);
}
float ceil(float v,int n,int|void m)
{
	m=m||10;
	return predef::ceil(v*pow(m,n))/pow(m,n);
}
float round(float v,int n,int|void m)
{
	m=m||10;
	return predef::round(v*pow(m,n))/pow(m,n);
}
