private mapping array2mapping=set_weak_flag(([]),Pike.WEAK_INDICES);

final mixed array_query(array(mapping)|mapping a,string key)/*{{{*/
{
	if(arrayp(a)||objectp(a)&&a->`[..]){
		if(array2mapping[a]&&array2mapping[a][key]){
			return array2mapping[a][key];
		}
		array2mapping[a]=array2mapping[a]||set_weak_flag(([]),Pike.WEAK_VALUES);
		foreach(a[sizeof(array2mapping[a])..],mapping b){
			array2mapping[a][b["_id_"]]=b;
			if(b["_id_"]==key)
				return b;
		}
	}else if(mappingp(a)||objectp(a)&&a->_m_delete){
		return a[key];
	}
}/*}}}*/
final mixed array_set(array(mapping)|mapping a,string key,mixed val)/*{{{*/
{
	if(arrayp(a)||objectp(a)&&a->`[..]){
		int found;
		foreach(a;int i;mapping b){
			if(b["_id_"]==key){
				if(array2mapping[a]&&array2mapping[a][key]){
					array2mapping[a][key]=val;
				}
				//ASSERT(key==val["_id_"]);
				a[i]=val;
				found=1;
			}
		}
		if(found)
			return val;
	}else if(mappingp(a)||objectp(a)&&a->_m_delete){
		a[key]=val;
		return val;
	}
	return UNDEFINED;
}/*}}}*/

