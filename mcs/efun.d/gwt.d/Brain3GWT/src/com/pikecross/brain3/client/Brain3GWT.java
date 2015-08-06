package com.pikecross.brain3.client;

import com.google.gwt.user.client.Window;
import com.google.gwt.user.client.Timer;
import com.google.gwt.http.client.Request;
import com.google.gwt.http.client.Response;
import com.google.gwt.http.client.RequestBuilder;
import com.google.gwt.http.client.URL;
import com.google.gwt.http.client.RequestCallback;
import com.google.gwt.http.client.RequestException;
import com.pikecross.brain3.shared.FieldVerifier;
import com.google.gwt.core.client.EntryPoint;
import com.google.gwt.core.client.GWT;
import com.google.gwt.user.client.Command;
import com.google.gwt.user.client.DOM;
import com.google.gwt.user.client.DeferredCommand;
import com.google.gwt.event.dom.client.ClickEvent;
import com.google.gwt.event.dom.client.ClickHandler;
import com.google.gwt.event.dom.client.ScrollEvent;
import com.google.gwt.event.dom.client.ScrollHandler;
import com.google.gwt.event.dom.client.ChangeEvent;
import com.google.gwt.event.dom.client.ChangeHandler;
import com.google.gwt.event.logical.shared.ValueChangeEvent;
import com.google.gwt.event.logical.shared.ValueChangeHandler;
import com.google.gwt.event.dom.client.KeyCodes;
//import com.google.gwt.event.dom.client.KeyUpEvent;
//import com.google.gwt.event.dom.client.KeyUpHandler;
import com.google.gwt.event.dom.client.KeyPressEvent;
import com.google.gwt.event.dom.client.KeyPressHandler;
import com.google.gwt.user.client.rpc.AsyncCallback;
import com.google.gwt.user.client.ui.FormHandler;
import com.google.gwt.user.client.ui.FormSubmitEvent;
import com.google.gwt.user.client.ui.FormSubmitCompleteEvent;
import com.google.gwt.user.client.ui.FocusWidget;
import com.google.gwt.user.client.ui.FocusPanel;
import com.google.gwt.user.client.ui.Button;
import com.google.gwt.user.client.ui.DialogBox;
import com.google.gwt.user.client.ui.HTML;
import com.google.gwt.user.client.ui.InlineHTML;
import com.google.gwt.user.client.ui.Label;
import com.google.gwt.user.client.ui.Image;
import com.google.gwt.user.client.ui.RootPanel;
import com.google.gwt.user.client.ui.TextBox;
import com.google.gwt.user.client.ui.Frame;
import com.google.gwt.user.client.ui.TextBoxBase;
import com.google.gwt.user.client.ui.PasswordTextBox;
import com.google.gwt.user.client.ui.VerticalPanel;
import com.google.gwt.user.client.ui.HorizontalPanel;
import com.google.gwt.user.client.ui.HasVerticalAlignment;
import com.google.gwt.event.dom.client.HasClickHandlers;
import com.google.gwt.event.logical.shared.HasValueChangeHandlers;
import com.google.gwt.event.dom.client.BlurHandler;
import com.google.gwt.event.dom.client.BlurEvent;
import com.google.gwt.user.client.ui.FlowPanel;
import com.google.gwt.user.client.ui.ScrollPanel;
import com.google.gwt.user.client.ui.InsertPanel;
import com.google.gwt.user.client.ui.FormPanel;
import com.google.gwt.user.client.ui.FileUpload;
import com.google.gwt.user.client.ui.Panel;
import com.google.gwt.user.client.ui.Widget;
import com.google.gwt.user.client.ui.CheckBox;
import com.google.gwt.user.client.ui.ListBox;
import com.google.gwt.user.client.ui.TextArea;
import com.google.gwt.dom.client.Style;
import com.google.gwt.dom.client.Style.Unit;
import com.google.gwt.xml.client.XMLParser;
import com.google.gwt.xml.client.Document;
//import com.google.gwt.dom.client.Element;
import com.google.gwt.xml.client.Element;
import com.google.gwt.xml.client.Node;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Set;

import com.allen_sauer.gwt.dnd.client.VetoDragException;
import com.allen_sauer.gwt.dnd.client.DragContext;
import com.allen_sauer.gwt.dnd.client.PickupDragController;
import com.allen_sauer.gwt.dnd.client.drop.DropController;
import com.allen_sauer.gwt.dnd.client.drop.VerticalPanelDropController;
import com.allen_sauer.gwt.dnd.client.drop.HorizontalPanelDropController;
import com.allen_sauer.gwt.dnd.client.drop.FlowPanelDropController;

//import com.gc.gwt.wysiwyg.client.Editor;
//import gr.open.client.TinyMCE;

import com.google.gwt.json.client.JSONString;



/**
 * Entry point classes define <code>onModuleLoad()</code>.
 */
public class Brain3GWT implements EntryPoint {
  /**
   * The message displayed to the user when the server cannot be reached or
   * returns an error.
   */
  private static final String SERVER_ERROR = "An error occurred while "
      + "attempting to contact the server. Please check your network "
      + "connection and try again.";

  /**
   * Create a remote service proxy to talk to the server-side Greeting service.
   */
  private final GreetingServiceAsync greetingService = GWT.create(GreetingService.class);

  int clientWidth,clientHeight;

class MyMap{//{{{
	//ArrayList keys=new ArrayList();
	//ArrayList vals=new ArrayList();
	HashMap keys=new HashMap();
	//HashMap vals=new HashMap();
	//public ArrayList queryKeys(){return keys;}
	//public ArrayList queryVals(){return vals;}
	public Object[] queryKeys(){return keys.keySet().toArray();}
	public Object[] queryVals(){return keys.values().toArray();}
	public Object get(Object key)
	{
		return keys.get(key);
		/*
		for(int i=0;i<keys.size();i++){
			if(keys.get(i).equals(key)){
				return vals.get(i);
			}
		}
		return null;
		*/
	}
	public Object put(Object key,Object val)
	{
		keys.put(key,val);
		//vals.put(val,key);
		return val;
		/*
		for(int i=0;i<keys.size();i++){
			if(keys.get(i).equals(key)){
				vals.set(i,val);
				return vals.get(i);
			}
		}
		keys.add(key);
		vals.add(val);
		return val;
		*/
	}
	public Object remove(Object key)
	{
		//vals.remove(keys.get(key));
		return keys.remove(key);
		/*
		for(int i=0;i<keys.size();i++){
			if(keys.get(i).equals(key)){
				keys.remove(i);
				Object res=vals.get(i);
				vals.remove(i);
				return res;
			}
		}
		return null;
		*/
	}
	public Object removeValue(Object val)
	{
		Object[] a=queryKeys();
		for(int i=0;i<a.length;i++){
			if(get(a[i]).equals(val)){
				keys.remove(a[i]);
			}
		}
		return val;

		/*
		for(int i=0;i<keys.size();i++){
			if(vals.get(i).equals(val)){
				keys.remove(i);
				Object res=vals.get(i);
				vals.remove(i);
				return res;
			}
		}
		return null;
		*/
	}
}//}}}

  final void addWidgetCandidate(Widget widget,String candidate)
  {
	  if(widget instanceof ListBox){
		  ((ListBox)widget).addItem(candidate);
	  }
  }
  final void setWidgetData(Widget widget,String data)//{{{
  {
	  widget.getElement().setPropertyString("data",data);
	  if(widget instanceof Button){
		  if(widget.getElement().getPropertyString("is_htmlbutton")!=null){
			  ((Button)widget).setHTML(data);
		  }else{
			  ((Button)widget).setText(data);
		  }
	  }else if(widget instanceof InlineHTML){
		  ((InlineHTML)widget).setHTML(data);
	  }else if(widget instanceof Label){
		  ((Label)widget).setText(data);
	  }else if(widget instanceof Image){
		  ((Image)widget).setUrl(data);
	  }else if(widget instanceof TextBox){
		  ((TextBox)widget).setValue(data);
		  ((TextBox)widget).setTitle(data);
	  }else if(widget instanceof PasswordTextBox){
		  ((PasswordTextBox)widget).setValue(data);
	  }else if(widget instanceof CheckBox){
		  ((CheckBox)widget).setChecked(!data.equals("0"));
	  }else if(widget instanceof TextArea){
		  if(widget.getElement().getPropertyString("is_richedit")!=null){
			  setContent(data);
		  }else{
			  ((TextArea)widget).setText(data);
		  }
	  //}else if(widget instanceof Editor){
		  //((Editor)widget).setHTML(data);
	  //}else if(widget instanceof TinyMCE){
		  //((TinyMCE)widget).setText(data);
	  }else if(widget instanceof Frame){
		  ((Frame)widget).setUrl(data);
	  }else if(widget instanceof ListBox){
		  int selected=-1;
		  for(int i=0;i<((ListBox)widget).getItemCount();i++){
			  if(((ListBox)widget).getValue(i).equals(data)){
				  selected=i;
			  }
		  }
		  if(selected>=0){
			  ((ListBox)widget).setSelectedIndex(selected);
		  }

		  /*
		  String[] list=data.split("\n");
		  //if(isListBox==true){
			  //((ListBox)widget).setVisibleItemCount(list.size-1);
		  //}
		  int selected=-1;
		  for(int i=1;i<list.length;i++){
			  if(list[i].equals(list[0]))
				  selected=i-1;
			  ((ListBox)widget).addItem(list[i]);
		  }
		  if(selected>=0){
			  ((ListBox)widget).setSelectedIndex(selected);
		  }
		  */
	  }
  }//}}}
  public String convertHexToString(String hex){
 
	  StringBuilder sb = new StringBuilder();
	  StringBuilder temp = new StringBuilder();
 
	  //49204c6f7665204a617661 split into two characters 49, 20, 4c...
	  for( int i=0; i<hex.length()-1; i+=2 ){
 
	      //grab the hex in pairs
	      String output = hex.substring(i, (i + 2));
	      //convert hex to decimal
	      int decimal = Integer.parseInt(output, 16);
	      //convert the decimal to character
	      sb.append((char)decimal);
 
	      temp.append(decimal);
	  }
	  System.out.println("Decimal : " + temp.toString());
 
	  return sb.toString();
  }

ArrayList<Widget> visible_begin(Widget w)
{
	ArrayList<Widget> res=new ArrayList<Widget>();
	Widget p=w;
	while(p!=null){
		if(!p.isVisible()){
			res.add(p);
			p.setVisible(true);
		}
		p=p.getParent();
	}
	return res;
}

void visible_end(ArrayList<Widget> a)
{
	for(int i=0;i<a.size();i++){
		a.get(i).setVisible(false);
	}
}




  public int handle_cmds(String s)//{{{
  {
	  if(s.equals(""))
		  return 0;

	  int count=0;
	  String res=s;
	  String[] a=res.split("\n");
	  if(a[0].equals("<xml>")){
		  count++;
		  GWT.log("reshow ");
		  Document d=XMLParser.parse(res);
		  id2widget=new MyMap();
		  id2scrollhandler=new MyMap();
		  name2widget=new MyMap();
		  ArrayList aa=walk(d.getDocumentElement());
		  //RootPanel root=RootPanel.get("start");
		  root.clear();
		  for(int i=0;i<aa.size();i++){
			  root.add((Widget)aa.get(i));
		  }
		  //postWalk();

	  }else{
		  for(int i=0;i<a.length;i++){
			  String str=a[i];
			  if(str.length()>0&&str.charAt(str.length()-1)=='\r'){
				  str=str.substring(0,str.length()-1);
			  }
			  GWT.log("Got: "+str+".");
			  if(str.length()>0&&str.charAt(0)=='#'){
				  //NOOP
			  }else{
				  String[] b=str.split(" ",-1);
				  for(int k=0;k<b.length;k++){
					  GWT.log("word: "+b[k]+".");
				  }
				  ArrayList<String> tt=new ArrayList<String>();
				  for(int k=0;k<b.length;k++){
					  if(b[k].length()>1&&b[k].charAt(0)=='='){
						  if(b[k].charAt(1)=='H'){
							  String t=b[k].substring(3);
							  t=convertHexToString(t);
							  t=utf8ToString(t);
							  tt.add(t);
						  }else if(b[k].charAt(1)!='-'){
							  int j;
							  for(j=1;j<b[k].length()&&b[k].charAt(j)!='=';j++)
								  ;
							  int n=Integer.parseInt(b[k].substring(1,j));
							  String ss=b[k].substring(j+1);
							  for(int kk=k+1;kk<k+n;kk++){
								  ss+=" "+b[kk];
							  }
							  if(ss.length()>0&&ss.charAt(0)=='"'){
								  ss=com.google.gwt.json.client.JSONParser.parse(ss).isString().stringValue();
							  }
							  tt.add(ss);
							  k+=n-1;
						  }else{
							  String d=b[k].substring(2,3);
							  String t=b[k].substring(4).replaceAll(d," ");
							  tt.add(t);
						  }
					  }else{
						  tt.add(b[k]);
					  }
				  }
				  b=(String[])tt.toArray(b);
				  String cmd=b[0];

				  //fix upload bug:
				  if(cmd.length()>=5&&(cmd.substring(0,5).equals("<pre>")||cmd.substring(0,5).equals("<PRE>")))
					  cmd=cmd.substring(5);
				  else if(cmd.length()>=11&&(cmd.substring(0,11).equals("</pre><pre>")||cmd.substring(0,11).equals("</PRE><PRE>")))
					  cmd=cmd.substring(11);
				  if(cmd.length()>=1&&cmd.substring(cmd.length()-1).equals("\r")){
					  cmd=cmd.substring(0,cmd.length()-1);
				  }

				  if(cmd.equals("reset_cmd_sn")){
					  cmd_sn=0;
				  }else if(cmd.equals("delete")){
					  //delete container pos tmpflag
					  if(b.length>=4){
						  count++;
						  String container=b[1];
						  String pos=b[2];
						  String tmpflag=b[3];
						  Widget c=(Widget)id2widget.get(container);
						  if(c!=null){
							  if(c instanceof InsertPanel){
								  InsertPanel t=(InsertPanel)c;
								  int pp=Integer.parseInt(pos);
								  Widget w=t.getWidget(pp);
								  if(tmpflag!="1")
									  cleanUp((Widget)w);
								  t.remove(pp);
								  if(tmpflag!="1")
									  removeWidget((Widget)w);
							  }else if(c instanceof ScrollPanel){
								  ScrollPanel t=(ScrollPanel)c;
								  Widget w=t.getWidget();
								  if(tmpflag!="1")
									  cleanUp((Widget)w);
								  t.remove(w);
								  if(tmpflag!="1")
									  removeWidget((Widget)w);
							  }
						  }
						  /*
						  id2widget.remove(w.getElement().getId());
						  //id2widget.removeValue(w);
						  name2widget.remove(w.getElement().getPropertyString("name"));
						  //name2widget.removeValue(w);
						  */
					  }
				  }else if(cmd.equals("insert")){
					  //insert container before_widget data
					  if(b.length>=4){
						  count++;
						  String container=b[1];
						  int beforeWidget=Integer.parseInt(b[2]);
						  String data=b[3];
						  Document d=XMLParser.parse("<xml>"+data+"</xml>");
						  ArrayList aa=walk(d.getDocumentElement());
						  for(int j=0;j<aa.size();j++){
							  Widget c=(Widget)id2widget.get(container);
							  if(c!=null){
								  if(c instanceof InsertPanel){
									  InsertPanel t=(InsertPanel)c;
									  t.insert((Widget)aa.get(j),beforeWidget);
								  }else if(c instanceof ScrollPanel){
									  ScrollPanel t=(ScrollPanel)c;
									  t.add((Widget)aa.get(j));
								  }
							  }
						  }
						  //postWalk();
					  }
				  }else if(cmd.equals("reinsert")){
					  //reinsert container pos widget
					  if(b.length>=4){
						  count++;
						  String container=b[1];
						  int beforeWidget=Integer.parseInt(b[2]);
						  String id=b[3];
						  Widget w=(Widget)(id2widget.get(id));
						  Widget c=(Widget)id2widget.get(container);
						  if(w!=null&&c!=null){
							  if(c instanceof InsertPanel){
								  InsertPanel t=(InsertPanel)c;
								  if(w.getParent()!=null){
									  ((Panel)(w.getParent())).remove(w);
								  }
								  t.insert(w,beforeWidget);
							  }else if(c instanceof ScrollPanel){
								  ScrollPanel t=(ScrollPanel)c;
								  if(w.getParent()!=null){
									  ((Panel)(w.getParent())).remove(w);
								  }
								  t.add(w);
							  }
						  }
						  //((Panel)t).remove(w);//XXX: 需要验证
					  }
				  }else if(cmd.equals("show")){
					  //show widget
					  if(b.length>=2){
						  count++;
						  String id=b[1];
						  Widget w=(Widget)(id2widget.get(id));
						  if(w!=null)
							  w.setVisible(true);
					  }
				  }else if(cmd.equals("hide")){
					  //hide widget
					  if(b.length>=2){
						  count++;
						  String id=b[1];
						  Widget w=(Widget)(id2widget.get(id));
						  if(w!=null)
							  w.setVisible(false);
					  }
				  }else if(cmd.equals("disable")){
					  //disable widget
					  if(b.length>=2){
						  count++;
						  String id=b[1];
						  Widget w=(Widget)(id2widget.get(id));
						  if(w!=null){
							  if(w instanceof TextBoxBase){
								  ((TextBoxBase)w).setReadOnly(true);
							  }else if(w instanceof FocusWidget){
								  ((FocusWidget)w).setEnabled(false);
							  }
						  }
					  }
				  }else if(cmd.equals("enable")){
					  //enable widget
					  if(b.length>=2){
						  count++;
						  String id=b[1];
						  Widget w=(Widget)(id2widget.get(id));
						  if(w!=null){
							  if(w instanceof TextBoxBase){
								  ((TextBoxBase)w).setReadOnly(false);
							  }else if(w instanceof FocusWidget){
								  ((FocusWidget)w).setEnabled(true);
							  }
						  }
					  }
				  }else if(cmd.equals("set_cursor_pos")){
					  //set_cursor_pos widget cursor_pos
					  if(b.length>=3){
						  count++;
						  String id=b[1];
						  int cursor_pos=Integer.parseInt(b[2]);
						  Widget w=(Widget)(id2widget.get(id));
						  if(w!=null)
							  ((TextBoxBase)w).setCursorPos(cursor_pos);
					  }
				  }else if(cmd.equals("set_width")){
					  //set_width widget n percent min
					  if(b.length>=5){
						  count++;
						  String id=b[1];
						  int width=Integer.parseInt(b[2]);
						  int percent=Integer.parseInt(b[3]);
						  int min=Integer.parseInt(b[4]);
						  Widget w=(Widget)(id2widget.get(id));
						  if(w!=null){
							  int n;
							  if(width>=0){
								  n=width*percent/100;
								  if(n<min)
									  n=min;
							  }else{
								  int screenWidth=clientWidth;
								  n=(screenWidth+width)*percent/100;
								  if(n<min)
									  n=min;
							  }
							  int nn;
							  ArrayList vv=visible_begin(w);
							  w.setWidth(n+"px");
							  nn=w.getOffsetWidth();
							  if(nn!=n){
								  if(n-(nn-n)>=0)
									  w.setWidth(n-(nn-n)+"px");
							  }
							  visible_end(vv);
						  }
						  
					  }
				  }else if(cmd.equals("set_height")){
					  //set_height widget n percent min
					  if(b.length>=5){
						  count++;
						  String id=b[1];
						  int height=Integer.parseInt(b[2]);
						  int percent=Integer.parseInt(b[3]);
						  int min=Integer.parseInt(b[4]);
						  Widget w=(Widget)(id2widget.get(id));
						  if(w!=null){
							  int n;
							  if(height>=0){
								  n=height*percent/100;
								  if(n<min)
									  n=min;
							  }else{
								  int screenHeight=clientHeight;
								  n=(screenHeight+height)*percent/100;
								  if(n<min)
									  n=min;
							  }
							  int nn;
							  ArrayList vv=visible_begin(w);
							  w.setHeight(n+"px");
							  nn=w.getOffsetHeight();
							  if(nn!=n){
								  if(n-(nn-n)>=0)
									  w.setHeight(n-(nn-n)+"px");
							  }
							  visible_end(vv);
						  }
					  }
				  }else if(cmd.equals("set_data")){
					  //set_data widget data
					  if(b.length>=3){
						  count++;
						  String id=b[1];
						  String data=b[2];
						  Widget w=(Widget)(id2widget.get(id));
						  if(w!=null)
							  setWidgetData(w,data);
					  }
				  }else if(cmd.equals("set_candidates")){
					  //set_candidates widget candidate1 ...
					  if(b.length>=3){
						  count++;
						  String id=b[1];
						  ListBox w=(ListBox)(id2widget.get(id));
						  if(w!=null){
							  w.clear();
							  for(int j=2;j<b.length;j++){
								  addWidgetCandidate(w,b[j]);
							  }
						  }
					  }
				  }else if(cmd.equals("mark")){
					  if(b.length>=4){
						  count++;
						  String id=b[1];
						  String name=b[2];
						  String tagsStr=b[3];
						  Widget w=(Widget)(id2widget.get(id));
						  if(w!=null){
							  w.getElement().setPropertyString("name",name);
							  if(!tagsStr.equals("")){
								  //w.getElement().setPropertyString("tags",tagsStr);
								  w.getElement().setClassName(tagsStr);
								  widget2tags.put(w,tagsStr.split(" "));
							  }
							  w.setVisible(false);
							  w.setVisible(true);
						  }
					  }
				  }else if(cmd.equals("reset_scroll_position")){
					  if(b.length>=2){
						  count++;
						  String id=b[1];
						  ScrollPanel sp=(ScrollPanel)(id2widget.get(id));
						  if(sp!=null)
							  sp.setScrollPosition(0);
					  }
				  }else if(cmd.equals("update_scroll")){
					  if(b.length>=2){
						  count++;
						  String id=b[1];
						  MyScrollHandler h=(MyScrollHandler)(id2scrollhandler.get(id));
						  if(h!=null)
							  h.update();

					  }
				  }else if(cmd.equals("adjust_scroll_position")){
					  if(b.length>=4){
						  count++;
						  String id=b[1];
						  String sym=b[2];
						  String item=b[3];
						  ScrollPanel sp=(ScrollPanel)(id2widget.get(id));
						  Widget w=(Widget)(id2widget.get(item));
						  if(sp!=null&&w!=null){
							  GWT.log("w.getOffsetHeight(): "+w.getOffsetHeight()+".");
							  if(sym.equals("+")){
								  sp.setScrollPosition(sp.getScrollPosition()+w.getOffsetHeight());
							  }else if(sym.equals("-")){
								  sp.setScrollPosition(sp.getScrollPosition()-w.getOffsetHeight());
							  }
						  }
					  }
				  }else if(cmd.equals("adjust_scroll_position_and_delete")){
					  if(b.length>=4){
						  count++;
						  String id=b[1];
						  String container=b[2];
						  String pos=b[3];
						  InsertPanel t=(InsertPanel)(id2widget.get(container));
						  int pp=Integer.parseInt(pos);

						  ScrollPanel sp=(ScrollPanel)(id2widget.get(id));
						  if(t!=null&&sp!=null){
							  Widget w=(Widget)(t.getWidget(pp));

							  GWT.log("w.getOffsetHeight(): "+w.getOffsetHeight()+".");

							  int newpos=sp.getScrollPosition()-w.getOffsetHeight();

							  cleanUp(w);
							  t.remove(pp);
							  removeWidget(w);
							  sp.setScrollPosition(newpos);
						  }
					  }
				  }else if(cmd.equals("adjust_scroll_position_and_reinsert_to")){
					  if(b.length>=6){
						  count++;
						  String id=b[1];
						  String container=b[2];
						  String pos=b[3];
						  String other=b[4];
						  String other_pos=b[5];
						  InsertPanel t=(InsertPanel)(id2widget.get(container));
						  int pp=Integer.parseInt(pos);
						  int other_pp=Integer.parseInt(other_pos);

						  ScrollPanel sp=(ScrollPanel)(id2widget.get(id));
						  if(t!=null&&sp!=null){
						  Widget w=(Widget)(t.getWidget(pp));

						  GWT.log("w.getOffsetHeight(): "+w.getOffsetHeight()+".");

						  int newpos=sp.getScrollPosition()-w.getOffsetHeight();

						  InsertPanel t2=(InsertPanel)(id2widget.get(other));
						  if(t2!=null){
							  t2.insert(w,other_pp);
						  }
						  sp.setScrollPosition(newpos);
						  }
					  }
				  }else if(cmd.equals("adjust_scroll_position_and_insert")){
					  if(b.length>=5){
						  count++;
						  String id=b[1];
						  String container=b[2];
						  String pos=b[3];
						  int beforeWidget=Integer.parseInt(pos);
						  String data=b[4];
						  Document d=XMLParser.parse("<xml>"+data+"</xml>");
						  ArrayList aa=walk(d.getDocumentElement());
						  InsertPanel t=(InsertPanel)(id2widget.get(container));
						  ScrollPanel sp=(ScrollPanel)(id2widget.get(id));
						  if(t!=null&&sp!=null){
							  for(int j=0;j<aa.size();j++){
								  t.insert((Widget)aa.get(j),beforeWidget);
							  }

							  Widget w=(Widget)(t.getWidget(beforeWidget));
							  GWT.log("w.getOffsetHeight(): "+w.getOffsetHeight()+".");

							  int newpos=sp.getScrollPosition()+w.getOffsetHeight();

							  sp.setScrollPosition(newpos);
						  }
						  //postWalk();
					  }
				  }else if(cmd.equals("adjust_scroll_position_and_reinsert")){
					  if(b.length>=5){
						  count++;
						  String id=b[1];
						  String container=b[2];
						  String pos=b[3];
						  int beforeWidget=Integer.parseInt(pos);
						  String id2=b[4];
						  InsertPanel t=(InsertPanel)(id2widget.get(container));
						  Widget w=(Widget)(id2widget.get(id2));
						  ScrollPanel sp=(ScrollPanel)(id2widget.get(id));
						  if(t!=null&&w!=null&&sp!=null){
							  ((Panel)t).remove(w);
							  t.insert(w,beforeWidget);

							  int newpos=sp.getScrollPosition()+w.getOffsetHeight();

							  sp.setScrollPosition(newpos);
							  //postWalk();
						  }
					  }
				  }else if(cmd.equals("scroll_to_bottom")){
					  if(b.length>=2){
						  count++;
						  String id=b[1];
						  Widget w=(Widget)id2widget.get(id);
						  if(w!=null){
							  ScrollPanel sp=(ScrollPanel)w;
							  sp.scrollToBottom();
						  }
					  }
				  }else if(cmd.equals("set_color")){
					  if(b.length>=5){
						  count++;
						  String id=b[1];
						  String r=java.lang.Integer.toHexString(Integer.parseInt(b[2]));
						  String g=java.lang.Integer.toHexString(Integer.parseInt(b[3]));
						  String bb=java.lang.Integer.toHexString(Integer.parseInt(b[4]));
						  if(r.length()==1) r="0"+r;
						  if(g.length()==1) g="0"+g;
						  if(bb.length()==1) bb="0"+bb;
						  Widget w=(Widget)id2widget.get(id);
						  if(w!=null)
							  w.getElement().getStyle().setColor("#"+r+g+bb);
					  }
				  }else if(cmd.equals("set_bgcolor")){
					  if(b.length>=5){
						  count++;
						  String id=b[1];
						  String r=java.lang.Integer.toHexString(Integer.parseInt(b[2]));
						  String g=java.lang.Integer.toHexString(Integer.parseInt(b[3]));
						  String bb=java.lang.Integer.toHexString(Integer.parseInt(b[4]));
						  if(r.length()==1) r="0"+r;
						  if(g.length()==1) g="0"+g;
						  if(bb.length()==1) bb="0"+bb;
						  Widget w=(Widget)id2widget.get(id);
						  if(w!=null)
							  w.getElement().getStyle().setBackgroundColor("#"+r+g+bb);
					  }
				  }else if(cmd.equals("location")){
					  if(b.length>=2){
						  count++;
						  String url=b[1];
						  Window.Location.assign(url);
					  }
				  }else if(cmd.equals("open_window")){
					  if(b.length>=2){
						  count++;
						  String url=b[1];
						  String target="_blank";
						  if(b.length>=3){
							  target=b[2];
						  }
						  Window.open(url, target, null);

					  }
				  }else if(cmd.equals("<pre>")){//fix upload bug
				  }else if(cmd.equals("</pre>")){//fix upload bug
				  }else if(cmd.equals("<PRE>")){//fix upload bug
				  }else if(cmd.equals("</PRE>")){//fix upload bug
				  }else if(cmd.equals("")){//fix upload bug
				  }else{
					  GWT.UncaughtExceptionHandler handler=GWT.getUncaughtExceptionHandler();
					  String errorinfo=("CmdBase:Bad response\n data="+new JSONString(res)+"\ncmd="+new JSONString(cmd)).replaceAll("<","&lt;").replaceAll("<","&gt;");
					  handler.onUncaughtException(new Exception(errorinfo));
					  break;
				  }
			  }
		  }
	  }
	  return count;
  }//}}}

/*
private class MyCommand implements Command
{
	CmdBase c;
	String[] a;
	int idx;

	public MyCommand(CmdBase _c,String s)
	{
		c=_c;
		a=s.split("\n");
		idx=0;
	}

	public void execute() {
		handle_cmds(a[idx]);
		postWalk();
		idx++;
		//if(idx<a.length&&!a[idx].equals("")&&a[idx].split(" ")[0].equals("delete")){ //保证调整ScrollPanel position与删除节点同时执行
			//handle_cmds(a[idx]);
			//idx++;
		//}
		if(idx!=a.length){
			DeferredCommand.addCommand(this);
		}else{
			c.clearInCmd();
		}
	}
}
*/

int cmd_sn=0;
long last_cmd_time=0;

ArrayList<String> cmdQueue=new ArrayList<String>();

private class Keeper extends Timer//{{{
{
	boolean in_cmd=false;
	public void clearInCmd(){ in_cmd=false; }
	public void eval(String cmd)//{{{
	{
		recordAnalyticsHit(cmd);
		in_cmd=true;
		String[] a=cmd.split(" ",-1);
		String line = "from_gui "+cmd_sn+" ";
		cmd_sn++;
		last_cmd_time=(new java.util.Date()).getTime();
		for(int i=0;i<a.length;i++){
			GWT.log(a[i]);
			GWT.log(new Integer(a[i].length()).toString());
			if(a[i].length()>0&&a[i].charAt(0)=='['&&a[i].charAt(a[i].length()-1)==']'){
				String argname=a[i].substring(1,a[i].length()-1);
				String property=null;
				String[] aa=argname.split("#");
				GWT.log("argname="+argname);
				GWT.log("aa.length="+aa.length);
				if(aa.length==2){
					argname=aa[0];
					property=aa[1];
				}
				GWT.log("argname2="+argname);
				GWT.log("property="+property);
				Widget w=(Widget)(name2widget.get(argname));
				if(w instanceof TextArea){
					if(property!=null&&property.equals("cursor_pos")){
						((TextArea)w).setFocus(true);
						a[i]=new Integer(((TextArea)w).getCursorPos()).toString();
						//a[i]=new Integer(w.getElement().getPropertyInt("cursor_pos")).toString();
					}else{
						if(w.getElement().getPropertyString("is_richedit")!=null){
							String s=getContent();
							//setContent(s);
							a[i]=new JSONString(s).toString();
						}else{
							TextBoxBase textbox=(TextBoxBase)w;
							a[i]=new JSONString(textbox.getValue()).toString();
						}
					}
				}else if(w instanceof TextBoxBase){
					if(property!=null&&property.equals("cursor_pos")){
						((TextBoxBase)w).setFocus(true);
						a[i]=new Integer(((TextBoxBase)w).getCursorPos()).toString();
						//a[i]=new Integer(w.getElement().getPropertyInt("cursor_pos")).toString();
					}else{
						TextBoxBase textbox=(TextBoxBase)w;
						a[i]=new JSONString(textbox.getValue()).toString();
					}
				//}else if(w instanceof Editor){
					//a[i]=new JSONString(((Editor)w).getHTML()).toString();
				//}else if(w instanceof TinyMCE){
					//a[i]=new JSONString(((TinyMCE)w).getText()).toString();
				}else if(w instanceof CheckBox){
					CheckBox cb=(CheckBox)w;
					if(cb.getValue())
						a[i]="1";
					else
						a[i]="0";
				}else if(w instanceof ListBox){
					ListBox lb=(ListBox)w;
					int n=lb.getSelectedIndex();
					String s=lb.getValue(n);
					a[i]=new JSONString(s).toString();
				}
				/*
				a[i]=textbox.getValue();
        DialogBox dialogBox = new DialogBox(true, false);
        DOM.setStyleAttribute(dialogBox.getElement(), "backgroundColor", "#ABCDEF");
	String text=a[i];
        text = text.replaceAll(" ", "&nbsp;");
        dialogBox.setHTML("<pre>" + text + "</pre>");
        dialogBox.center();
	*/
			}
			line=line+a[i];
			if(i!=a.length-1)
				line=line+" ";
		}
		//url="/test_cmd.txt";
		String url = "/?cmd="+com.google.gwt.http.client.URL.encodeComponent(line);
		//String url = "/?cmd="+line;
		GWT.log("CmdBase: "+url+".");
		RequestBuilder builder = new RequestBuilder(RequestBuilder.GET,url);
		builder.setCallback(new RequestCallback(){
			public void onError(Request request, Throwable exception) {   
				GWT.log("onError:",exception);
				clearInCmd();
			}
			public void onResponseReceived(Request request, Response response) {
				//ignoreScroll++;
				GWT.UncaughtExceptionHandler handler=GWT.getUncaughtExceptionHandler();

				GWT.log(response.getStatusCode()+"\n");
				if(response.getStatusCode()==Response.SC_OK){   
					String res=response.getText();
					//if(enableSchedule){
						//DeferredCommand.addCommand(new MyCommand(CmdBase.this,res));
					//}else{
						int count=handle_cmds(res);
						postWalk();
						clearInCmd();
					//}
					onFinish();
				}else if(response.getStatusCode()!=0){
					handler.onUncaughtException(new Exception("CmdBase:StatusCode="+response.getStatusCode()));
					clearInCmd();
				}
				//ignoreScroll--;
			}
		});
		Request r;
		try{
			r=builder.send();  
		}catch(RequestException e){
			clearInCmd();
			GWT.UncaughtExceptionHandler handler=GWT.getUncaughtExceptionHandler();
			handler.onUncaughtException(e);
		}
	}//}}}
	public void onFinish() { run(); }
	int interval;
	public void run(){
		if(!in_cmd){
			if(cmdQueue.size()>0){
				String s=cmdQueue.get(0);
				eval(s);
				cmdQueue.remove(0);
			}
			if((new java.util.Date()).getTime()-last_cmd_time>30000)
				eval("noop");
		}
	}
	public Keeper(int n)
	{
		interval=n;
		scheduleRepeating(n);
	}

}//}}}
Keeper keeper=new Keeper(1000);


private class CmdBase /*extends Timer*/ //{{{
{
	public void eval(String cmd)
	{
		recordAnalyticsHit(cmd);
		cmdQueue.add(cmd);
	}
}//}}}

class MyClickHandler extends CmdBase implements ClickHandler{
	String cmd;
	public MyClickHandler(String _cmd)
	{
		cmd=_cmd;
	}
	public void onClick(ClickEvent event){
		eval(cmd);
	}
};
/*
class MyKeyPressHandler extends CmdBase implements KeyPressHandler{
	MyMap m;
	public MyKeyPressHandler(MyMap _m)
	{
		m=_m;
	}
	public void onKeyPress(KeyPressEvent event){
		eval((String)(m.get(new Integer(event.getUnicodeCharCode()))));
	}
};
*/
class MyStringValueChangeHandler extends CmdBase implements ValueChangeHandler<String>{
	String id;
	public MyStringValueChangeHandler(String _id){
		id=_id;
	}
	public void onValueChange(ValueChangeEvent<String> event)
	{
		eval("_widget_update_data_internal_ "+id+" "+new JSONString(event.getValue()).toString());
	}
}
class MyBooleanValueChangeHandler extends CmdBase implements ValueChangeHandler<Boolean>{
	String id;
	public MyBooleanValueChangeHandler(String _id){
		id=_id;
	}
	public void onValueChange(ValueChangeEvent<Boolean> event)
	{
		eval("_widget_update_data_internal_ "+id+" "+new JSONString(event.getValue()?"1":"0").toString());
	}
}
class MyListBoxChangeHandler extends CmdBase implements ChangeHandler{
	String id;
	ListBox list;
	public MyListBoxChangeHandler(String _id,ListBox _list){
		id=_id;
		list=_list;
	}
	public void onChange(ChangeEvent event) 
	{
		ListBox lb=list;
		int n=lb.getSelectedIndex();
		String s=lb.getValue(n);
		String res=new JSONString(s).toString();
		eval("_widget_update_data_internal_ "+id+" "+res);
	}
}
class MyFormHandler extends CmdBase implements FormHandler{
	FileUpload upload;
	public MyFormHandler(FileUpload _upload){
		upload=_upload;
	}
	public void onSubmit(FormSubmitEvent event){
	}
	public void onSubmitComplete(FormSubmitCompleteEvent event)
	{
		String res=event.getResults();
		handle_cmds(res);
		postWalk();
		upload.setEnabled(true);
	}
}

class MyScrollHandler extends Timer implements ScrollHandler{
	CmdBase c=new CmdBase();
	ScrollPanel panel;
	String cmd;
	//int inFinish=0;
	//boolean moreScroll=false;
	//boolean in_cmd=false;
	boolean hasScroll=false;
	boolean lastHasScroll=false;
	int lastPos=0;
	boolean updateFlag=false;
	String debug_info="";
	public void run() {
		if(panel==null||panel.getWidget()==null)
			return;
		int pos=(panel.getWidget().getAbsoluteTop()+panel.getWidget().getOffsetHeight()-panel.getAbsoluteTop()-panel.getOffsetHeight());
		if(lastHasScroll&&!hasScroll||pos<=0&&pos!=lastPos||updateFlag){
			if(cmdQueue.size()>0){
				hasScroll=true;
			}else{
				updateFlag=false;
				lastHasScroll=hasScroll;
				hasScroll=false;
				int lastLast=lastPos;
				lastPos=pos;
				c.eval(cmd+" "+panel.getElement().getId()+" "+(panel.getAbsoluteTop()-panel.getWidget().getAbsoluteTop())+" "+(panel.getOffsetHeight())+" "+lastPos+" "+lastLast+","+debug_info); 
			}
		}else{
			lastHasScroll=hasScroll;
			hasScroll=false;
		}
	}
	public void update() {
		updateFlag=true;
		run();
	}
	public MyScrollHandler(ScrollPanel _panel,String _cmd)
	{
		//enableSchedule=false/*true*/;
		panel=_panel;
		cmd=_cmd;
		scheduleRepeating(500);
	}
	public void onScroll(ScrollEvent event) {
		hasScroll=true;
		return;
	}
}

  /**
   * This is the entry point method.
   */
  DialogBox dialogBox = null;
  public void onModuleLoad() {
    // set uncaught exception handler
    GWT.setUncaughtExceptionHandler(new GWT.UncaughtExceptionHandler() {
      public void onUncaughtException(Throwable throwable) {
        String text = "Uncaught exception: ";
        while (throwable != null) {
          StackTraceElement[] stackTraceElements = throwable.getStackTrace();
          text += throwable.toString() + "\n";
          for (int i = 0; i < stackTraceElements.length; i++) {
            text += "    at " + stackTraceElements[i] + "\n";
          }
          throwable = throwable.getCause();
          if (throwable != null) {
            text += "Caused by: ";
          }
        }
	if(dialogBox == null)
		dialogBox = new DialogBox(true, false);

        DOM.setStyleAttribute(dialogBox.getElement(), "backgroundColor", "#ABCDEF");
        System.err.print(text);
        text = text.replaceAll(" ", "&nbsp;");
        dialogBox.setHTML("<pre>" + text + "</pre>");
        dialogBox.center();
      }
    });
 
    //setupIframe();
    // use a deferred command so that the handler catches onModuleLoad2() exceptions
    DeferredCommand.addCommand(new Command() {
      public void execute() {
        onModuleLoad2();
      }
    });
  }
MyMap id2widget=new MyMap(); MyMap id2scrollhandler=new MyMap();
MyMap name2widget=new MyMap();
MyMap widget2tags=new MyMap();

FocusPanel focus;

/*private class TinyMCERemover extends Timer
{
	String id;
	public TinyMCERemover(String _id)
	{
		id=_id;
		scheduleRepeating(500);
	}
	public void run() 
	{
		removeEditor(id);
	};
}*/

void cleanUp(Widget w)
{
	if(w.getElement().getPropertyString("is_richedit")!=null){
		focus.setFocus(true);
		removeEditor(w.getElement().getId());
	}
	if(w instanceof InsertPanel){
		InsertPanel p=(InsertPanel)w;
		for(int i=0;i<p.getWidgetCount();i++){
			cleanUp(p.getWidget(i));
		}
	}
}

void removeWidget(Widget w)
{
	/*if(w.getElement().getPropertyString("is_richedit")!=null){
		focus.setFocus(true);
		TinyMCERemover tr=new TinyMCERemover(w.getElement().getId());
	}*/
	widget2tags.remove(w);
	id2widget.remove(w.getElement().getId());
	MyScrollHandler h=((MyScrollHandler)(id2scrollhandler.get(w.getElement().getId())));
	if(h!=null)
		h.cancel();
	id2scrollhandler.remove(w.getElement().getId());
	name2widget.remove(w.getElement().getPropertyString("name"));
	if(w instanceof InsertPanel){
		InsertPanel p=(InsertPanel)w;
		for(int i=0;i<p.getWidgetCount();i++){
			removeWidget(p.getWidget(i));
		}
	}
	//w.getElement().removeFromParent();//TinyMCE need it
}

class DndRule{//{{{
	String[] widgetTags;
	String[] containerTags,lastTags,nextTags;
	String ruleType;
	String cmd;
	public DndRule( String[] _widgetTags, String[] _containerTags,String[] _lastTags,String[] _nextTags, String _ruleType,String _cmd)
	{
		widgetTags=_widgetTags;
		containerTags=_containerTags;
		lastTags=_lastTags;
		nextTags=_nextTags;
		ruleType=_ruleType;
		cmd=_cmd;
	}
	/*
	public String queryTargetKey()
	{
		int i;
		String res="";
		for(i=0;i<containerTags.length;i++){
			res+=containerTags[i]+",";
		}
		res+=";";
		for(i=0;i<lastTags.length;i++){
			res+=lastTags[i]+",";
		}
		res+=";";
		for(i=0;i<nextTags.length;i++){
			res+=nextTags[i]+",";
		}
		res+=";";
		return res;
	}
	*/
	public void sendCmd(Widget draggable,Widget container,Widget last,Widget next,boolean cancel)
	{
		CmdBase c=new CmdBase();
		String idDraggable=draggable.getElement().getId();
		String nameDraggable=draggable.getElement().getPropertyString("name");
		String idContainer=container.getElement().getId();
		String nameContainer=container.getElement().getPropertyString("name");
		int pos=0;
		if(last==null){
			pos=0;
		}else if(container instanceof InsertPanel){
			if(next==null){
				pos=((InsertPanel)container).getWidgetCount();
			}else{
				pos=((InsertPanel)container).getWidgetIndex(next);
			}
		}
		if(container instanceof InsertPanel){
			if(((InsertPanel)container).getWidgetIndex(draggable)!=-1){
				if(((InsertPanel)container).getWidgetIndex(next)>((InsertPanel)container).getWidgetIndex(draggable)){
					pos=pos-1;
				}
			}
		}
		if(cancel)
			c.eval(cmd+" "+nameDraggable+" "+nameContainer+" "+pos);
		else
			c.eval("_widget_move_ "+idDraggable+" "+idContainer+" "+pos+" "+cmd+" "+nameDraggable+" "+nameContainer+" "+pos);
	}
	public boolean isDropPostion(Widget container,Widget last,Widget next){
		String[] containerTags1=(String[])widget2tags.get(container);
		String[] lastTags1=(String[])widget2tags.get(last);
		String[] nextTags1=(String[])widget2tags.get(next);
		return isA(containerTags1,containerTags)&&isA(lastTags1,lastTags)&&isA(nextTags1,nextTags);
	}
};//}}}

ArrayList<DndRule> dndRules=new ArrayList<DndRule>();
  
String cmds_queue="";
ArrayList _walk(Node body)
{
	ArrayList<Widget> res=new ArrayList<Widget>();
	Node node=body.getFirstChild();
	while(node!=null){
		if(node.getNodeType()==Node.ELEMENT_NODE){
			Element p=(Element)node;
			Widget widget=null;
			boolean isListBox=false;
			boolean isFileUploadDownload=false;
			if(p.getAttribute("class")!=null){
				GWT.log(p.getAttribute("class"));
			}
			if(p.getAttribute("class").equals("dnd_rules")){
				Node rulenode=node.getFirstChild();
				while(rulenode!=null){
					GWT.log(rulenode.toString());
					Element pp=(Element)rulenode;
					if(pp.getAttribute("class").equals("dnd_rule")){
						String widgetTypeStr=pp.getAttribute("widget_type");
						String containerTagsStr=pp.getAttribute("container_tags");
						String lastTagsStr=pp.getAttribute("last_tags");
						String nextTagsStr=pp.getAttribute("next_tags");
						String ruleType=pp.getAttribute("rule_type");
						String cmd=pp.getAttribute("cmd");

						dndRules.add(new DndRule(widgetTypeStr.split(" "),containerTagsStr.split(" "),lastTagsStr.split(" "),nextTagsStr.split(" "),ruleType,cmd));

					}
					rulenode=rulenode.getNextSibling();
				}
			}else if(p.getAttribute("class").equals("v")){
				widget=new VerticalPanel();
			}else if(p.getAttribute("class").equals("h")){
				widget=new HorizontalPanel();
				//((HorizontalPanel)widget).setVerticalAlignment(HasVerticalAlignment.ALIGN_BOTTOM);
			}else if(p.getAttribute("class").equals("focus_panel")){
				widget=new FocusPanel();
			}else if(p.getAttribute("class").equals("flow_panel")){
				widget=new FlowPanel();
			}else if(p.getAttribute("class").equals("scroll_panel")){
				widget=new ScrollPanel();
			}else if(p.getAttribute("class").equals("button")){
				widget=new Button();
			}else if(p.getAttribute("class").equals("htmlbutton")){
				widget=new Button();
				widget.getElement().setPropertyString("is_htmlbutton","true");
			}else if(p.getAttribute("class").equals("text")){
				widget=new Label();
			}else if(p.getAttribute("class").equals("image")){
				widget=new Image();
			}else if(p.getAttribute("class").equals("html")){
				widget=new InlineHTML();
			}else if(p.getAttribute("class").equals("textbox")){
				widget=new TextBox();
			}else if(p.getAttribute("class").equals("passwd_textbox")){
				widget=new PasswordTextBox();
			}else if(p.getAttribute("class").equals("checkbox")){
				widget=new CheckBox();
			}else if(p.getAttribute("class").equals("textarea")){
				widget=new TextArea();
				do{
					final TextArea w=(TextArea)widget;
					w.addBlurHandler(new BlurHandler(){
						public void onBlur(BlurEvent event)
						{
							w.getElement().setPropertyInt("cursor_pos",w.getCursorPos());
						}
					});
				}while(false);
			}else if(p.getAttribute("class").equals("richedit")){
				widget=new TextArea();
				final String id=p.getAttribute("k");
				final com.google.gwt.user.client.Element ele=widget.getElement();
				DeferredCommand.addCommand(new Command() {
					public void execute() {
						ele.setPropertyString("is_richedit","true");
						attachEditor(id);
					}
				});
				//widget=new TinyMCE();
				//((Editor)widget).setWidth("300px");
			}else if(p.getAttribute("class").equals("frame")){
				widget=new Frame();
				DOM.setIntAttribute(widget.getElement(), "frameBorder", 0); 
				widget.getElement().getStyle().setBorderWidth(0,Style.Unit.PX);
			}else if(p.getAttribute("class").equals("dropdown")){
				widget=new ListBox();
				isListBox=false;
				((ListBox)widget).setVisibleItemCount(1);
			}else if(p.getAttribute("class").equals("listbox")){
				widget=new ListBox();
				isListBox=true;
				((ListBox)widget).setVisibleItemCount(2);
			}else if(p.getAttribute("class").equals("file_upload")){
				final FormPanel form=new FormPanel();
				final FileUpload upload = new FileUpload();
				isFileUploadDownload=true;
				//form.setAction("/?cmd=_file_upload_ "+p.getAttribute("click_cmd"));
				form.setAction("/");
				form.addFormHandler(new MyFormHandler(upload));
				form.setEncoding(FormPanel.ENCODING_MULTIPART);
				form.setMethod(FormPanel.METHOD_POST);
				HorizontalPanel panel = new HorizontalPanel();
				form.setWidget(panel);
				TextBox tb=new TextBox();
				tb.setName("cmd");
				tb.setValue("from_gui -1 _file_upload_ "+p.getAttribute("click_cmd"));
				panel.add(tb);
				tb.setVisible(false);
				upload.addChangeHandler(new ChangeHandler(){
				public void onChange(ChangeEvent event) 
				{
					form.submit();
					upload.setEnabled(false);
				}

				});
				upload.setName(p.getAttribute("k"));
				panel.add(upload);
				widget=form;
			}else if(p.getAttribute("class").equals("file_download")){
				final FormPanel form=new FormPanel("_self");
				GWT.log("file_download");
				isFileUploadDownload=true;
				//form.setAction("/?cmd=_file_upload_ "+p.getAttribute("click_cmd"));
				form.setAction("/");
				//form.addFormHandler(new MyFormHandler());
				form.setEncoding(FormPanel.ENCODING_URLENCODED);
				form.setMethod(FormPanel.METHOD_POST);
				HorizontalPanel panel = new HorizontalPanel();
				//panel.add(HTML("download flag"));
				form.setWidget(panel);
				TextBox tb=new TextBox();
				tb.setName("cmd");
				tb.setValue(p.getAttribute("click_cmd"));
				panel.add(tb);
				tb.setVisible(false);
				panel.add(new Button(p.getAttribute("data"), new ClickHandler() {
					public void onClick(ClickEvent event) {
						form.submit();
					}
				}));

				widget=form;
			}
			String cmds="";
			if(widget!=null){
				widget.getElement().setId(p.getAttribute("k"));
				id2widget.put(p.getAttribute("k"),widget);

				if(p.getAttribute("name")!=null){
					widget.getElement().setPropertyString("name",p.getAttribute("name"));
					name2widget.put(p.getAttribute("name"),widget);
				}
				int idx=0;
				while(p.getAttribute("candidate"+idx)!=null){
					addWidgetCandidate(widget,p.getAttribute("candidate"+idx));
					idx++;
				}
				String data=p.getAttribute("data");
				if(data!=null){
					setWidgetData(widget,data);
				}
				if(p.getAttribute("click_cmd")!=null){
					String cmd=p.getAttribute("click_cmd");
					widget.getElement().setPropertyString("click_cmd",cmd);
					if(widget instanceof HasClickHandlers){
						((HasClickHandlers)widget).addClickHandler(new MyClickHandler(cmd));
					}
					if(widget instanceof ScrollPanel){
						final MyScrollHandler h=new MyScrollHandler((ScrollPanel)widget,cmd);
						((ScrollPanel)widget).addScrollHandler(h);

						id2scrollhandler.put(p.getAttribute("k"),h);
						h.update();
					}
				}
				if(p.getAttribute("tags")!=null){
					String tagsStr=p.getAttribute("tags");
					//widget.getElement().setPropertyString("tags",tagsStr);
					widget.getElement().setClassName(tagsStr);
					widget2tags.put(widget,tagsStr.split(" "));
				}
				if(p.getAttribute("disabled")!=null){
					String v=p.getAttribute("disabled");
					if(widget instanceof TextBoxBase){
						((TextBoxBase)widget).setReadOnly(true);
					}else if(widget instanceof FocusWidget)
						((FocusWidget)widget).setEnabled(false);
				}else{
					if(widget instanceof FocusWidget)
						((FocusWidget)widget).setEnabled(true);
				}
				if(p.getAttribute("cursor_pos")!=null){
					cmds+="set_cursor_pos "+p.getAttribute("k")+p.getAttribute("cursor_pos")+"\n";
				}
				if(p.getAttribute("width")!=null){
					String v=p.getAttribute("width");
					int pos=v.indexOf(":")+1;
					int pos2=v.indexOf(":",pos)+1;
					//widget.setWidth(v+"px");
					int width=Integer.parseInt(v.substring(0,pos-1));
					int percent=Integer.parseInt(v.substring(pos,pos2-1));
					int min=Integer.parseInt(v.substring(pos2));
					int n;
					if(width>=0){
						n=width*percent/100;
						if(n<min)
							n=min;
					}else{
						int screenWidth=clientWidth;
						n=(screenWidth+width)*percent/100;
						if(n<min)
							n=min;
					}
					Widget w=widget;
					w.setWidth(n+"px");
					cmds+="set_width "+p.getAttribute("k")+" "+width+" "+percent+" "+min+"\n";
				}
				if(p.getAttribute("height")!=null){
					String v=p.getAttribute("height");
					int pos=v.indexOf(":")+1;
					int pos2=v.indexOf(":",pos)+1;
					GWT.log("v="+v);
					int height=Integer.parseInt(v.substring(0,pos-1));
					int percent=Integer.parseInt(v.substring(pos,pos2-1));
					int min=Integer.parseInt(v.substring(pos2));
					GWT.log("height="+height);
					int n;
					if(height>=0){
						n=height*percent/100;
						if(n<min)
							n=min;
					}else{
						int screenHeight=clientHeight;
						n=(screenHeight+height)*percent/100;
						if(n<min)
							n=min;
						GWT.log("screenHeight="+screenHeight);
					}
					Widget w=widget;
					w.setHeight(n+"px");
					cmds+="set_height "+p.getAttribute("k")+" "+height+" "+percent+" "+min+"\n";
				}
				if(p.getAttribute("invisible")!=null){ //must after width&height
					String v=p.getAttribute("invisible");
					cmds+="hide "+p.getAttribute("k")+"\n";
					//widget.setVisible(false);
				}
				if(p.getAttribute("scroll_to_bottom")!=null){
					cmds+="scroll_to_bottom "+p.getAttribute("k")+"\n";
					//((ScrollPanel)widget).scrollToBottom();
				}
				if(p.getAttribute("key_binding")!=null){
					String[] a=p.getAttribute("key_binding").split(";");
					for(int i=0;i<a.length;i++){
						MyMap m=new MyMap();
						String str=a[i];
						if(!str.equals("")){
							String[] b=str.split(":");
							if(b.length>=2){
								String keycode,cmd;
								keycode=b[0];
								cmd=b[1];
								int c=Integer.parseInt(keycode);
								m.put(new Integer(c),cmd);
							}
						}
					}
				}
				if(p.getAttribute("color")!=null){
					widget.getElement().getStyle().setColor(p.getAttribute("color"));
				}
				if(p.getAttribute("bgcolor")!=null){
					widget.getElement().getStyle().setBackgroundColor(p.getAttribute("bgcolor"));
				}
				idx=0;
				while(p.getAttribute("cmd"+idx)!=null){
					cmds+=p.getAttribute("cmd"+idx)+"\n";
					idx++;
				}
				if(widget instanceof PasswordTextBox
						||widget instanceof TextBox
						||widget instanceof TextArea
				  )
				{
					((HasValueChangeHandlers<String>)widget).addValueChangeHandler(new MyStringValueChangeHandler(p.getAttribute("k")));
				}
				if(widget instanceof CheckBox)
				{
					((HasValueChangeHandlers<Boolean>)widget).addValueChangeHandler(new MyBooleanValueChangeHandler(p.getAttribute("k")));
				}
				if(widget instanceof ListBox)
				{
					((ListBox)widget).addChangeHandler(new MyListBoxChangeHandler(p.getAttribute("k"),(ListBox)widget));
				}
				if(widget instanceof Panel&&!isFileUploadDownload){
					ArrayList items=_walk(node);
					for(int i=0;i<items.size();i++){
						((Panel)widget).add((Widget)(items.get(i)));
					}
				}
				cmds_queue+=cmds;
				res.add(widget);
			}
		}
		node=node.getNextSibling();
	}
	return res;
};
private ArrayList walk(Node body)
{
	ArrayList res=_walk(body);
	return res;
}
private void postWalk()
{
	while(!cmds_queue.equals("")){
		String t=cmds_queue;
		cmds_queue="";
		handle_cmds(t);
	}
}

ArrayList draggables=new ArrayList();
class MyPickupDragController extends PickupDragController{
	String[] tags;

	public void setTags(String[] _tags){tags=_tags;}
	public String[] queryTags(){return tags;}
	public MyPickupDragController()
	{
		super(RootPanel.get(),false);
	}
	public void dragStart()
	{
		super.dragStart();
	}
}

//ArrayList<MyPickupDragController> dragControllers=new ArrayList<MyPickupDragController>();
MyMap dragControllers=new MyMap();

private boolean isA(String[] item,String[] type)//{{{
{
	if(item==null){
		item=new String[0];
	}
	for(int i=0;i<type.length;i++){
		if(!type[i].equals("")){
			boolean found=false;
			for(int j=0;j<item.length;j++){
				if(type[i].equals(item[j])){
					found=true;
				}
			}
			if(!found)
				return false;
		}
	}
	return true;
}//}}}
private void walkDraggables(Panel panel)//{{{
{
	java.util.Iterator<Widget> i=panel.iterator();
	while(i.hasNext()){
		Widget w=i.next();
		GWT.log("draggables.got: "+w.toString());
		if(widget2tags.get(w)!=null){
			String[] widget_tags=(String[])widget2tags.get(w);
			for(int j=0;j<dndRules.size();j++){
				DndRule r=dndRules.get(j);
				if(isA(widget_tags,r.widgetTags)){
					GWT.log("draggables.add: "+w.toString());
					draggables.add(w);
					break;
				}
			}
		}
		if(w instanceof Panel){
			walkDraggables((Panel)w);
		}

	}
}//}}}
private void createDragControllers()//{{{
{
	for(int i=0;i<draggables.size();i++){
		String[] tags=(String[])widget2tags.get(draggables.get(i));
		java.util.Arrays.sort(tags);
		String res="";
		for(int j=0;j<tags.length;j++){
			res+=tags[j]+" ";
			if(dragControllers.get(res)==null){
				MyPickupDragController p=new MyPickupDragController();
				p.setTags(tags);
				dragControllers.put(res,p);
			}
			GWT.log("makeDraggable: "+(((Widget)draggables.get(i)).toString()));
			((PickupDragController)dragControllers.get(res)).makeDraggable((Widget)draggables.get(i)); 
		}
	}
}//}}}
public  class MyVerticalDropController extends VerticalPanelDropController{//{{{
	private VerticalPanel myDropTarget;
	private DndRule dndRule;
	private Widget positioner;
	public DndRule queryDndRule(){return dndRule;}
	public MyVerticalDropController(DndRule rule,VerticalPanel panel)
	{
		super(panel);
		dndRule=rule;
		myDropTarget=panel;
	}
	protected Widget newPositioner(DragContext context)
	{
		positioner=super.newPositioner(context);
		return positioner;
	}
	private Widget draggable,last,next;
	public void onPreviewDrop(DragContext context) throws VetoDragException
	{
		draggable=context.draggable;
		String node=draggable.getElement().getPropertyString("node");

		int pos=myDropTarget.getWidgetIndex(positioner);
		last=null;
		if(pos-1>=0){
			last=myDropTarget.getWidget(pos-1);
			if(last==draggable){
				last=null;
				if(pos-2>=0){
					last=myDropTarget.getWidget(pos-2);
				}
			}
		}
		next=null;
		if(pos+1<myDropTarget.getWidgetCount()){
			next=myDropTarget.getWidget(pos+1);
			if(next==draggable){
				next=null;
				if(pos+2<myDropTarget.getWidgetCount()){
					next=myDropTarget.getWidget(pos+2);
				}
			}
		}
		if(!dndRule.isDropPostion(myDropTarget,last,next)){
			throw(new VetoDragException());
		}
		if(dndRule.ruleType=="deny"){
			//dndRule.sendCmd(draggable,myDropTarget,last,next);
			DeferredCommand.addCommand(new Command() {
				public void execute() {
					myCancel();
				}
			});
			throw(new VetoDragException());
		}
		super.onPreviewDrop(context);
	}
	private void myCancel()
	{
		dndRule.sendCmd(draggable,myDropTarget,last,next,true);
	}
	private void myFinish()
	{
		dndRule.sendCmd(draggable,myDropTarget,last,next,false);
	}
	public void onDrop(DragContext context)
	{
		super.onDrop(context);
		DeferredCommand.addCommand(new Command() {
			public void execute() {
				myFinish();
			}
		});
		
	}
}//}}}
public  class MyHorizontalDropController extends HorizontalPanelDropController{//{{{
	private HorizontalPanel myDropTarget;
	private DndRule dndRule;
	private Widget positioner;
	public DndRule queryDndRule(){return dndRule;}
	public MyHorizontalDropController(DndRule rule,HorizontalPanel panel)
	{
		super(panel);
		dndRule=rule;
		myDropTarget=panel;
	}
	protected Widget newPositioner(DragContext context)
	{
		positioner=super.newPositioner(context);
		return positioner;
	}
	private Widget draggable,last,next;
	public void onPreviewDrop(DragContext context) throws VetoDragException
	{
		draggable=context.draggable;
		String node=draggable.getElement().getPropertyString("node");

		int pos=myDropTarget.getWidgetIndex(positioner);
		last=null;
		if(pos-1>=0){
			last=myDropTarget.getWidget(pos-1);
			if(last==draggable){
				last=null;
				if(pos-2>=0){
					last=myDropTarget.getWidget(pos-2);
				}
			}
		}
		next=null;
		if(pos+1<myDropTarget.getWidgetCount()){
			next=myDropTarget.getWidget(pos+1);
			if(next==draggable){
				next=null;
				if(pos+2<myDropTarget.getWidgetCount()){
					next=myDropTarget.getWidget(pos+2);
				}
			}
		}
		if(!dndRule.isDropPostion(myDropTarget,last,next)){
			throw(new VetoDragException());
		}
		if(dndRule.ruleType=="deny"){
			//dndRule.sendCmd(draggable,myDropTarget,last,next);
			DeferredCommand.addCommand(new Command() {
				public void execute() {
					myCancel();
				}
			});
			throw(new VetoDragException());
		}
		super.onPreviewDrop(context);
	}
	private void myCancel()
	{
		dndRule.sendCmd(draggable,myDropTarget,last,next,true);
	}
	private void myFinish()
	{
		dndRule.sendCmd(draggable,myDropTarget,last,next,false);
	}
	public void onDrop(DragContext context)
	{
		super.onDrop(context);
		DeferredCommand.addCommand(new Command() {
			public void execute() {
				myFinish();
			}
		});
		
	}
}//}}}
public  class MyFlowDropController extends FlowPanelDropController{//{{{
	private FlowPanel myDropTarget;
	private DndRule dndRule;
	private Widget positioner;
	public DndRule queryDndRule(){return dndRule;}
	public MyFlowDropController(DndRule rule,FlowPanel panel)
	{
		super(panel);
		dndRule=rule;
		myDropTarget=panel;
	}
	protected Widget newPositioner(DragContext context)
	{
		positioner=super.newPositioner(context);
		return positioner;
	}
	private Widget draggable,last,next;
	public void onPreviewDrop(DragContext context) throws VetoDragException
	{
		draggable=context.draggable;
		String node=draggable.getElement().getPropertyString("node");

		int pos=myDropTarget.getWidgetIndex(positioner);
		last=null;
		if(pos-1>=0){
			last=myDropTarget.getWidget(pos-1);
			if(last==draggable){
				last=null;
				if(pos-2>=0){
					last=myDropTarget.getWidget(pos-2);
				}
			}
		}
		next=null;
		if(pos+1<myDropTarget.getWidgetCount()){
			next=myDropTarget.getWidget(pos+1);
			if(next==draggable){
				next=null;
				if(pos+2<myDropTarget.getWidgetCount()){
					next=myDropTarget.getWidget(pos+2);
				}
			}
		}
		if(!dndRule.isDropPostion(myDropTarget,last,next)){
			throw(new VetoDragException());
		}
		if(dndRule.ruleType=="deny"){
			//dndRule.sendCmd(draggable,myDropTarget,last,next);
			DeferredCommand.addCommand(new Command() {
				public void execute() {
					myCancel();
				}
			});
			throw(new VetoDragException());
		}
		super.onPreviewDrop(context);
	}
	private void myCancel()
	{
		dndRule.sendCmd(draggable,myDropTarget,last,next,true);
	}
	private void myFinish()
	{
		dndRule.sendCmd(draggable,myDropTarget,last,next,false);
	}
	public void onDrop(DragContext context)
	{
		super.onDrop(context);
		DeferredCommand.addCommand(new Command() {
			public void execute() {
				myFinish();
			}
		});
		
	}
}//}}}

private void walkDropables(Panel panel)//{{{
{
	java.util.Iterator<Widget> i=panel.iterator();
	while(i.hasNext()){
		Widget w=i.next();
		if(widget2tags.get(w)!=null){
			String[] widget_tags=(String[])widget2tags.get(w);
			for(int j=0;j<dndRules.size();j++){
				DndRule r=dndRules.get(j);
				if(isA(widget_tags,r.containerTags)){
					ArrayList<PickupDragController> a=new ArrayList<PickupDragController>();
					Object[] vals=dragControllers.queryVals();
					for(int k=0;k<vals.length;k++){
						MyPickupDragController dragController=(MyPickupDragController)vals[k];
						String[] tags=dragController.queryTags();
						if(isA(tags,r.widgetTags)){
							a.add(dragController);
						}
					}
					if(w instanceof Panel){
						if(w instanceof VerticalPanel){
							DropController dropController=new MyVerticalDropController(r,(VerticalPanel)w);
							for(int l=0;l<a.size();l++){
								a.get(l).registerDropController(dropController);
							}
						}else if(w instanceof HorizontalPanel){
							DropController dropController=new MyHorizontalDropController(r,(HorizontalPanel)w);
							for(int l=0;l<a.size();l++){
								a.get(l).registerDropController(dropController);
							}
						}else if(w instanceof FlowPanel){
							DropController dropController=new MyFlowDropController(r,(FlowPanel)w);
							for(int l=0;l<a.size();l++){
								a.get(l).registerDropController(dropController);
							}
						}
					}
				}
			}
		}
		if(w instanceof Panel){
			walkDropables((Panel)w);
		}

	}
}//}}}

RootPanel root;
RootPanel root2;
private void onModuleLoad2() {
	//setupIframe();
	clientWidth=Window.getClientWidth();
	if(clientWidth<=0) clientWidth=600;
	clientHeight=Window.getClientHeight();
	if(clientHeight<=0) clientHeight=600;

	root=RootPanel.get("start");
	root2=RootPanel.get();
	focus=new FocusPanel();
	focus.setVisible(false);
	root2.add(focus);
	String data=root.getElement().getInnerHTML();
	com.google.gwt.dom.client.Node node=root.getElement().getFirstChild();
	while(node!=null){
		root.getElement().removeChild(node);
		node=root.getElement().getFirstChild();
	}
	GWT.log(data);
	Document d=XMLParser.parse(data);
	ArrayList aa=walk(d.getDocumentElement());
	root.clear();
	for(int i=0;i<aa.size();i++){
		root.add((Widget)(aa.get(i)));
	}
	postWalk();
	walkDraggables(root);
	createDragControllers();
	walkDropables(root);
}

public static native String getAvailHeight() /*-{
					       var screenHeight = screen.availHeight + "";
					       return screenHeight;
					       }-*/;
public static native String getAvailWidth() /*-{
					      var screenWidth = screen.availWidth + "";
					      return screenWidth;
					      }-*/;

public static native void attachEditor(String itemId) /*-{
    $wnd.tinyMCE.execCommand('mceAddControl', false, itemId);
}-*/;

public static native void removeEditor(String itemId) /*-{
    $wnd.tinyMCE.execCommand('mceRemoveControl', false, itemId);
}-*/;

public static native String getContent() /*-{
    var html = null;
    if ($wnd.tinyMCE.activeEditor) {
        html = $wnd.tinyMCE.activeEditor.getContent();
    }
    return html;
}-*/;

public static native void setContent(String content) /*-{
    if ($wnd.tinyMCE.activeEditor) {
        $wnd.tinyMCE.activeEditor.setContent(content);
    }
}-*/;


public static native String utf8ToString(String utftext) /*-{
		var string = "";
		var i = 0;
		var c = c1 = c2 = 0;
 
		while ( i < utftext.length ) {
 
			c = utftext.charCodeAt(i);
 
			if (c < 128) {
				string += String.fromCharCode(c);
				i++;
			}
			else if((c > 191) && (c < 224)) {
				c2 = utftext.charCodeAt(i+1);
				string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
				i += 2;
			}
			else {
				c2 = utftext.charCodeAt(i+1);
				c3 = utftext.charCodeAt(i+2);
				string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
				i += 3;
			}
 
		}
 
		return string;

}-*/;
public static native void recordAnalyticsHit(String pageName) /*-{
if($wnd._gaq){
	$wnd._gaq.push(['_trackPageview', pageName])
	    //$wnd.pageTracker._trackPageview(pageName);
}
}-*/;

public static native void setupIframe() /*-{
if($wnd.parent){
	document.domain="pikecross.com";
	$wnd.document.domain="pikecross.com";
	var h=$wnd.parent.innerheight;
	if(!h){
		if($wnd.parent.document){
			if($wnd.parent.document.documentElement)
				h=$wnd.parent.document.documentElement.clientHeight;
			else
				h=$wnd.parent.document.body.clientHeight;
		}else{
			alert("no parent document");
		}
	}
	//alert("h="+h);

	if($wnd.parent.document){
		var a=$wnd.parent.document.getElementsByTagName("iframe");
		if(a.length){
			a[0].scrolling="no";//firefox only
			a[0].height=h-175;
		}else{
			alert("no iframe");
		}
		//var path_bar_container=$wnd.parent.document.getElementById("portal-breadcrumbs");
		//if(path_bar_container){
			//while(path_bar_container.childNodes.length){
				//path_bar_container.removeChild(path_bar_container.childNodes[0]);
			//}
		//}
	}else{
		alert("no parent document");
	}
}else{
	alert("no parent");
}
}-*/;

}
