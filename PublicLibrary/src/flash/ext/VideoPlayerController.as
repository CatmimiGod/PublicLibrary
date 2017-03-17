package flash.ext
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NetworkControllerEvent;
	import flash.events.ProgressEvent;
	import flash.events.VideoPlayerEvent;
	import flash.geom.Rectangle;
	import flash.net.Socket;
	import flash.utils.setTimeout;
	
	[Event(name="VideoPlayerEvent.UPDATE", type="flash.events.VideoPlayerEvent")]
	[Event(name="VideoPlayerEvent.CUE_POINT", type="flash.events.VideoPlayerEvent")]
	
	/**
	 *	C# VideoPlayer 控制对象
	 * 	@author Administrator
	 */	
	public final class VideoPlayerController extends EventDispatcher
	{
		private var _port:int;
		private var _address:String;
		
		private var _socket:Socket;
		private var _queue:Vector.<String>
		private var _updateVideoState:Boolean;
		
		private var _stateInfo:Object;
		private var _cuePositions:Vector.<Number>;
		
		private var _dataEvent:Event = new Event("data", false);
		
		
		/**
		 * Constructor.
		 * @param port	视频窗体端口号
		 * @param updateVideoState	是否需要时实返回视频播放状态及相关数据
		 */
		public function VideoPlayerController(updateVideoState:Boolean = false, port:int = 2010, address:String = "127.0.0.1")
		{
			_port = port;
			_address = address;
			_updateVideoState = updateVideoState;
			
			_queue = new Vector.<String>();
			_cuePositions = new Vector.<Number>();
			_stateInfo = new Object();
			//_stateInfo = {id:-1, rect:new Rectangle(), visible:true, state:0, position:0, duration:0, volume:100, rate:1, mute:false, cuePoint:""};
			
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
					trace("VideoPlayer Connect...", e.type);
					setTimeout(_socket.connect, 500, _address, _port);
					break;
				
				case Event.CONNECT:
					sendQueues();
					//sendData("getVideoState");
					//sendData("getWindowState");
					break;
				
				case ProgressEvent.SOCKET_DATA:
					
					this.dispatchEvent(_dataEvent);			
					if(_dataEvent.isDefaultPrevented())	return;
					
					analyseData(_socket.readUTFBytes(_socket.bytesAvailable));
					break;
			}
		}
		
		private var _arr:Array;
		private var _list:Array;
		/**	分析接收的数据	*/
		protected function analyseData(value:String):void
		{
			//trace(value);
			_list = value.split("&");
			for(var i:int = 0; i < _list.length; i ++)
			{
				if(_list[i].indexOf("=") != -1)
				{
					_arr = _list[i].split("=");
					_stateInfo[_arr[0]] = _arr[1];
				}
			}
			
			
			if(_updateVideoState && _stateInfo.state == 0x03)
			{
				if(_stateInfo.hasOwnProperty("cuePoint") && _stateInfo.cuePoint != "null")
					analyseCuePoint(_stateInfo.position);
			}
			else
			{
				if(_stateInfo.hasOwnProperty("cuePointEvent"))
					this.dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.CUE_POINT, false, false, _stateInfo.position, _stateInfo.cuePointEvent, _stateInfo.position, _stateInfo.id));
			}
			
			delete _stateInfo.cuePointEvent;
			
			this.dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.UPDATE));			
			if(_updateVideoState && _stateInfo.state > 0x02)
				sendData("func=getState");
		}
		
		/**	分析提示点	*/
		private function analyseCuePoint(position:Number):void
		{
			var cuePoints:Array = _stateInfo.cuePoint.split(",");
			var count:uint = cuePoints.length;
			if(count <= 0)	return;
			
			if(_cuePositions.length != count)
				_cuePositions.length = count;
			
			var dec:uint;
			var cp:Number;
			var pos:Number;
			
			for(var i:int = 0; i < count; i ++)
			{
				dec = getDecimalPlaces(cuePoints[i]);	//获取原设置节点的小数点位
				pos = Math.floor(position * dec) / dec;	//计算当前位置的数据点，与设置的小数点位相同
				cp = Number(cuePoints[i]);				
				
				if(cp == pos && _cuePositions[i] != pos)	//计算值是否相等，如果相等就记录下来，如果不相等则记录为0
				{
					_cuePositions[i] = pos;
					//trace("节点了", _cuePositions[i], _stateInfo.position);
					this.dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.CUE_POINT, false, false, cp, i, _stateInfo.position, _stateInfo.id));
					break;
				}
				else
				{
					if(_cuePositions[i] != pos)
						_cuePositions[i] = 0;
				}
			}
		}
		
		[inline]
		protected static function getDecimalPlaces(num:String):uint
		{
			var dec:int = 1;
			var len:int = num.indexOf(".") != -1 ? num.split(".")[1].length : 0;
			
			if(len > 0)
			{
				for(var i:int = 0; i < len; i ++)
					dec *= 10;
			}
			
			return dec;
		}
		
		/**	发送URL变量数据 	 @param value	 */		
		protected function sendData(value:String):void
		{
			if(_socket == null)		return;
			
			if(_socket.connected)
			{
				//trace(value);
				_socket.writeUTFBytes(value);
				_socket.flush();
			}
			else
			{
				_queue.unshift(value);
			}
		}
		
		/**	发送失败的命令，重新排队发送	*/
		protected function sendQueues():void
		{
			if(_queue.length == 0)	return;
			//trace("sendQueues...");
			var queue:Vector.<String> = _queue.concat();
			var count:int = queue.length;
			
			_queue = new Vector.<String>();
			for(var i:int = count - 1; i >= 0; i --)
			{
				//trace(queue[i]);
				//sendData(queue[i]);
				setTimeout(sendData, 100 * i, queue[i]);
				queue.splice(i, 1);
			}
		}
		
		/**	关闭视频窗体并清理对象内存	*/
		public function dispose():void
		{
			sendData("func=dispose");
			
			_queue = null;
			_stateInfo = null;
			
			_socket.removeEventListener(Event.CLOSE, onSocketEventHandler);
			_socket.removeEventListener(Event.CONNECT, onSocketEventHandler);
			_socket.removeEventListener(IOErrorEvent.IO_ERROR, onSocketEventHandler);
			_socket.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketEventHandler);
			
			if(_socket.connected)	_socket.close();
			_socket = null;
		}
		
		//Window
		//----------------------------------------------------------------------
		/**
		 *	设置尺寸大小 
		 * @param rect
		 */		
		public function setSize(...args):void
		{
			//var rs:String = rect.x + "," + rect.y + "," + rect.width + "," + rect.height;
			
			if(args.length == 1 && args[0] is Object)
				_stateInfo.rect = args[0].x + "," + args[0].y + "," + args[0].width + "," + args[0].height;
			else(args.length == 4)
				_stateInfo.rect = args[0] + "," + args[1] + "," + args[2] + "," + args[3];
				
			sendData("func=setSize&args=" + _stateInfo.rect);
		}
		
		/**视频窗体置底*/
		public function windowToBack():void{	sendData("func=windowToBack");		}
		
		/**视频窗体置顶*/
		public function windowToFront():void{		sendData("func=windowToFront");		}
		
		/**	设置窗体的可见性	*/
		public function get visible():Boolean{	return _stateInfo.visible == "true";	}
		public function set visible(value:Boolean):void
		{
			sendData("func=visible&args=" + value.toString());
			_stateInfo.visible = value;
		}
		
		
		//Video
		//-----------------------------------------------------------------
		/**	加载视频并播放	*/
		public function load(url:String, autoPlay:Boolean = true, loop:Boolean = false):void	
		{		
			sendData("func=loopPlay&args=" + loop.toString());
			
			//sendData("func=autoPlay&args=" + autoPlay.toString());
			//sendData("func=load&args=" + url);
			
			setTimeout(sendData, 100, "func=autoPlay&args=" + autoPlay.toString());
			setTimeout(sendData, 200, "func=loadPlay&args=" + url);
		}
		
		/**	加载视频列表配置的视频序号	*/
		public function loadIndex(id:int):void{		sendData("func=loadIndex&args=" + id);		}
		
		/** 播放视频*/
		public function play():void{		sendData("func=play");		}
		/**	暂停视频	*/
		public function pause():void{		sendData("func=pause");		}
		/**	停止视频	*/
		public function stop():void{		sendData("func=stop");		}
		
		/**	快进	*/
		public function fastForward():void{		sendData("func=fastForward");		}		
		/**	快退		*/
		public function fastReverse():void{		sendData("func=fastReverse");		}
		
		/**	设置视频音量 */		
		public function get volume():int{		return _stateInfo.volume;		}
		public function set volume(value:int):void
		{
			if(value >= 0 && value <= 100)
			{
				_stateInfo.volume = value;
				sendData("func=volume&args=" + _stateInfo.volume);
			}
		}
		
		/**	设置是否静音 */		
		public function get mute():Boolean{		return _stateInfo.mute == "true";		}
		public function set mute(value:Boolean):void
		{
			_stateInfo.mute = value;
			sendData("func=mute&args=" + value.toString());
		}
		
		/**	video position	*/
		public function get position():Number{	return _stateInfo.position;	}
		public function set position(value:Number):void
		{
			if(value >= 0)
			{
				_stateInfo.position = value;
				sendData("func=position&args=" + _stateInfo.position);
			}
		}
		
		/** 比率，速度*/
		public function get rate():uint{	return _stateInfo.rate;		}
		public function set rate(value:uint):void
		{
			_stateInfo.rate = value;
			sendData("func=rate&args=" + _stateInfo.rate);
		}
		
		/**	视频的持续时间	*/
		public function get duration():Number	{	return _stateInfo.duration;		}
		
		/**	视频是否正在播放	*/
		public function get playing():Boolean{	return _stateInfo.state == 0x03;	}
		
		/**	视频播放状态	*/
		public function get videoState():uint{	return _stateInfo.state;		}
		
	}
}