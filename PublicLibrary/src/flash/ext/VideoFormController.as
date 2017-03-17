/////////////////////////////////////////////////////////////////////
//0x00  Undefined			0x01  Stopped			0x02  Paused
//0x03  Playing				0x04  ScanForward		0x05  ScanReverse
//0x06  Buffering			0x07  Waiting			0x08  MediaEnded
//0x09  Transitioning		0x10  Ready				0x11  Reconnecting			0x12  Last
//
//End Stste
//netState:3  state:wmppsPlaying
//netState:8  state:wmppsMediaEnded
//netState:9  state:wmppsTransitioning
//netState:1  state:wmppsStopped
//Loop State
//netState:8  state:wmppsMediaEnded
//netState:9  state:wmppsTransitioning
//netState:3  state:wmppsPlaying
//
//接口命令，可多个命令同时发送，用';'隔开
//func=updateStatus         		//网络功能，更新所有客户端数据
//func=activate             		//激活窗体
//func=setSize&args=x,y,w,h 		//窗体大小及位置
//func=topMost&args=true|false    	//窗体是否置顶
//func=visible&args=true|false    	//窗体是否可见，窗体隐藏时视频会自动暂停
//
//func=play                 //控制播放视频
//func=pause                //控制视频暂停
//func=stop                 //控制视频停止，停止后play会从头开始播放
//func=fastForward          //控制视频快进播放（用处不大）
//func=fastReverse          //控制视频快退播放（用处不大）
//
//func=playIndex&args=int         //播放视频列表中指定索引的视频
//func=setLanguage&args=language	//针对播放列表有多语言的功能
//
//func=url&args=url               //设置URL
//func=autoStart&args=true|false  //是否自动播放
//func=autoLoop&args=true|false   //是否自动循环播放
//func=volume&args=0-100          //视频音量设置0-100
//func=position&args=Number       //视频播放位置
//
//func=dispose                    //关闭窗体清理对象
//
//callBack=Method&args=args       //回调
//////////////////////////////////////////////////////////////////////
package flash.ext
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.Socket;
	import flash.utils.setTimeout;

	/**
	 *	VideoForm Controller  TMD，设计总是不太合理，Bug太多，重新设计，注意版本号
	 * 	@author Administrator
	 *  @example 示例
	 * <listing version="3.0">
	 * var videoForm:VideoFormController = new VideoFormController(this);
	 * videoForm.addEventListener("data", videoFormEventHandler);
	 * videoForm.addEventListener("change", videoFormEventHandler);
	 * 
	 * this.addEventListener(Event.ENTER_FRAME, onEnterFrameHandler);
	 * 
	 * function videoFormEventHandler(e:Event):void
	 * {
	 * 		switch(e.type)
	 * 		{
	 * 			case "data":
	 * 				e.preventDefault();
	 * 				trace(status.data);
	 * 				break;
	 * 				
	 * 			case "change":
	 * 				trace(videoForm.state);
	 * 				break;
	 * 		}
	 * }
	 * function onEnterFrameHandler(e:Event):void
	 * {
	 * 		videoForm.updateStatus();		//update status
	 * 		trace(videoForm.position);		//get position info
	 * }
	 * public function callBack(...args):void
	 * {
	 * 		//videoList.xml callBack
	 * }
	 * </listing>
	 */	
	public class VideoFormController extends EventDispatcher
	{
		public static const VERSION:String = "Bate 1.0.0";
		
		/**	
		 * 	是否忽略执行错误，默认为 true
		 * 	@default true	
		 */
		public var ignoreError:Boolean = true;
		
		private var _port:int;
		private var _address:String;
		
		private var _socket:Socket;
		private var _commands:String;
		
		private var _status:Object;
		private var _module:Object;
		
		private var _dataEvent:Event = new Event("data", false);
		private var _changeEvent:Event = new Event(Event.CHANGE);
		
		/**
		 *	 Constructor.
		 * @param module	回调时的执行对象
		 * @param port
		 * @param address
		 */
		public function VideoFormController(module:Object = null, port:int = 2010, address:String = "127.0.0.1")
		{
			_port = port;
			_address = address;
			
			_status = {};
			_module = module;
			_commands = "";
			
			_socket = new Socket(_address, _port);
			_socket.addEventListener(Event.CLOSE, onSocketEventHandler);
			_socket.addEventListener(Event.CONNECT, onSocketEventHandler);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onSocketEventHandler);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketEventHandler);
		}
		
		private function onSocketEventHandler(e:Event):void
		{
			switch(e.type)
			{
				case Event.CLOSE:
				case IOErrorEvent.IO_ERROR:
					//trace("VideoFormController Connect...", e.type);
					setTimeout(_socket.connect, 500, _address, _port);
					break;
				
				case Event.CONNECT:
					updateStatus();
					
					if(_commands != "")
					{
						sendCommand(_commands);
						_commands = "";
					}
					break;
				
				case ProgressEvent.SOCKET_DATA:
					_status["data"] = _socket.readUTFBytes(_socket.bytesAvailable);
					
					this.dispatchEvent(_dataEvent);					//???
					if(_dataEvent.isDefaultPrevented())		return;
					
					analyseData(_status["data"]);
					break;
			}
		}
		
		private var _dataVar:Object;
		
		/**	分析数据	*/
		protected function analyseData(data:String):void
		{
			_dataVar = AS.decodeURLVariables(data);
			if(_dataVar.hasOwnProperty("func"))
			{
				if(this[_dataVar.func] != null)
					this[_dataVar.func].apply(this, _dataVar.args.split(","));
			}
			else if(_dataVar.hasOwnProperty("callBack") && _module != null)
			{
				AS.callProperty(_module, _dataVar.callBack, _dataVar.args, ignoreError);
			}
			else
			{
				trace("VideoFormController::未处理的数据[" + data + "]");
			}
		}
		
		/**	
		 * 更新参数	
		 * @param ...args x:0,y:0,width:960,height:540,visible:true,topMost:false,currentIndex:0,length:2,state:9,position:0,duration:0,volume:100,language:cn
		 */
		private function updateArguments(...args):void
		{
			var array:Array;
			
			for(var i:int = 0; i < args.length; i ++)
			{
				if(args[i].indexOf(":") == -1)	break;
				
				array = args[i].split(":");
				if(array.length == 2)
				{
					_status[array[0]] = array[1];	//trace(array[0], array[1]);
					if(array[0] == "state")	this.dispatchEvent(_changeEvent);
				}
			}
		}
		
		/**	
		 * 发送控制指令性数据，可多个指令发送，示例：sendCommand("func=pause", "func=visible&amp;args=false"); 
		 * @param value	 
		 */		
		public function sendCommand(...args):void
		{
			if(_socket == null || args.length <= 0)		return;
			
			var data:String = args.join(";");		//trace(data);
			if(_socket.connected)
			{
				_socket.writeUTFBytes(data + ";");
				_socket.flush();
			}
			else
			{
				_commands = _commands != "" ? _commands + ";" + data : data;
				//trace(_commands);
			}
		}
		
		/** 清理对象*/
		public function dispose():void
		{	
			sendCommand("func=dispose");	
			
			_module = null;
			_status = null;
			_dataVar = null;
			_dataEvent = null;
			_changeEvent = null;
			
			_socket.removeEventListener(Event.CLOSE, onSocketEventHandler);
			_socket.removeEventListener(Event.CONNECT, onSocketEventHandler);
			_socket.removeEventListener(IOErrorEvent.IO_ERROR, onSocketEventHandler);
			_socket.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketEventHandler);
			
			if(_socket.connected)	_socket.close();
			_socket = null;
		}
		
		/**	请求更新数据状态	*/
		public function updateStatus():void{		sendCommand("func=updateStatus");	}
		/**	激活窗体	*/
		public function activate():void{		sendCommand("func=activate");	}
		
		/**
		 * 设置窗体位置及大小(uint类型或number类型，number类型只能是比例值)(x,y,width,height)
		 */
		public function setSize(...args):void{	sendCommand("func=setSize&args=" + args.join(","));		}
		/**	播放指定的视频索引	*/
		public function playIndex(index:int):void{	sendCommand("func=playIndex&args=" + index); 	}
		
		/**
		 * 播放视频
		 * @param url		如果为空，则播放当前视频，此参数不为空时后面的参数才会有效
		 * @param autoStart
		 * @param autoLoop
		 * @param volume		0-100
		 */
		public function play(url:String = null, autoStart:Boolean = true, autoLoop:Boolean = true, volume:uint = 100):void
		{	
			if(url != null && url != "" && url != "null")
			{
				sendCommand("func=autoStart&args=" + autoStart.toString(),
					"func=autoLoop&args=" + autoLoop.toString(),
					"func=volume&args=" + volume.toString(),
					"func=url&args=" + url + "");
			}
			else
			{
				sendCommand("func=play");
			}
		}
		/**	停止播放视频	*/
		public function stop():void{	sendCommand("func=stop");	}
		/**	暂停播放视频	*/
		public function pause():void{	sendCommand("func=pause");	}
		
		/**	视频快进	*/
		public function fastForward():void{	sendCommand("func=fastForward");	}
		/**	视频后退	*/
		public function fastReverse():void{	sendCommand("func=fastReverse");	}
		
		/**	获取状态信息，所有状态信息数据都在此变量	*/
		public function get status():Object{	return _status;		}
		
		/**	播放状态	@see VideoPlayerState	*/
		public function get state():uint{		return _status.state;		}
		/**视频是否正在播放*/
		public function get playing():Boolean{	return _status.state == 0x03;		}
		
		/**	视频持续时间	*/
		public function get duration():Number{	return _status.duration;	}
		
		/**	视频播放位置	*/
		public function get position():Number{	return _status.position;	}
		public function set position(value:Number):void{		sendCommand("func=position&args=" + value);		}
		
		/**	是否置顶窗体	*/
		public function get topMost():Boolean{	return _status.hasOwnProperty("topMost") && _status.topMost.toString().toLowerCase() == "true";		}
		public function set topMost(value:Boolean):void{		sendCommand("func=topMost&args=" + value.toString());	}
		
		/**	窗体是否可见	*/
		public function get visible():Boolean{	return _status.hasOwnProperty("visible") && _status.visible.toString().toLowerCase() == "true" ;		}
		public function set visible(value:Boolean):void{		sendCommand("func=visible&args=" + value.toString());		}
		
		/**	设置语言	*/
		public function get language():String{	return _status["language"];	}
		public function set language(value:String):void{		sendCommand("func=setLanguage&args=" + value);	}
		
		
	}
}