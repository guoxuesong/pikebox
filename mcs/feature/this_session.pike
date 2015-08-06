DAEMON:
private object curr_session;

//! @appears this_session
//!
//!	Return current session
object this_session(){return curr_session;};

//! @appears set_this_session
//!
//!	Set current session
object set_this_session(object session){return curr_session=session;};
