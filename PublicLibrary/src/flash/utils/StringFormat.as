package flash.utils
{
	/**
	 *	link C# String.Format
	 * 	StringFormat("funcName=getOnlineResult&amp;args={0}:{1}", _socket.localAddress, _socket.localPort); 
	 */	
	public function StringFormat(string:String, ...args):String
	{
		for(var i:int = 0; i < args.length; i++)
			string = string.replace(new RegExp("\\{" + i + "\\}", "gm"), args[i]);  
		
		return string; 
	}
}