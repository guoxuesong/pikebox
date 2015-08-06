#ifdef DYNPROG
#define CLASS_OBJECT(BASE, FEATURES ... ) (.DynClass(#BASE#, #FEATURES#))
#define CLASS(BASE, FEATURES ... ) (.DynClass(#BASE#, #FEATURES#)->cast("program"))
#else
#define CLASS(BASE, FEATURES ... ) .DynClass(#BASE#, #FEATURES#)
#endif
#define STATIC(BASE, FEATURES ... ) .DynClass(#BASE#, #FEATURES#)->find_static( )
//要求feature是常数，否则报 Parent pointer lost, cannot inherit
