package flash.media
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	
	/**
	 * 	当声音播放完成后发生。
	 */ 
	[Event(name="soundComplete", type="flash.events.Event")]
	
	/**
	 *	LocalSound 本地加载声音对象
	 * 2016.10.20修改继承关系，改为Sprite，子级做显示效果
	 * 
	 * 	@example 示例：
	 * 	<listing version="3.0">
	 * 	var music:LocalSound = new LocalSound("music01.mp3", true);
	 * 	music.loop = true;
	 * 	music.load("music02.mp3", false);
	 *  music.play();
	 * 	</listing>
	 */
	public class LocalSound extends Sprite
	{
		protected var sound:Sound;
		protected var soundChannel:SoundChannel = new SoundChannel();		
		
		private var _url:String = null;
		private var _tempPosition:Number = 0;
		
		private var _playing:Boolean = false;
		
		/**	是否自动播放  @default true	*/
		public var autoplay:Boolean = true;
		
		/**	是否循环播放	@default false	*/
		public var loop:Boolean = false;		
		
		/**
		 * 本地加载声音对象，可重复加载声音对象。
		 * @param url:String 声音文件路径
		 * @param autoplay:Boolean 自动播放
		 */ 
		public function LocalSound(url:String = null, autoplay:Boolean = true):void
		{
			load(url, autoplay);
		}
		
		/**
		 * 从指定 URL 加载外部 MP3 文件。当声音正在播放时，停止播放，加载新的声音文件。
		 * 
		 * @param url:String 声音文件路径
		 * @param autoplay:Boolean 自动播放
		 */ 
		public function load(url:String, autoplay:Boolean = true):void
		{
			stop();
			this._url = url;
			this.autoplay = autoplay;
			
			if(_url != null)
			{
				dispose();
				
				sound = new Sound();
				sound.load(new URLRequest(_url));	
				sound.addEventListener(Event.COMPLETE, onLoadCompleteHandler, false, 0, true);
			}
		}
		
		/**
		 * @private
		 *	加载声音时的事件处理
		 */ 
		protected function onLoadCompleteHandler(e:Event):void
		{
			if(autoplay)	play(0, this.loop);
			sound.removeEventListener(Event.COMPLETE, onLoadCompleteHandler);
		}
		
		/**
		 *	开始播放声音。
		 *	@param startTime:Number 属性指示声音文件中当前播放的位置（以毫秒为单位）
		 */
		public function play(startTime:Number = 0, loop:Boolean = false):void
		{			
			if(soundChannel)
			{
				soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundChannelHandler);
				soundChannel.stop();
				soundChannel = null;
			}
			
			_playing = true;
			_tempPosition = 0;
			this.loop = loop;
			
			soundChannel = sound.play(startTime);	
			soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundChannelHandler, false, 0, true);
		}
		
		/**
		 * @private
		 * 声音播放完成后
		 */ 
		private function onSoundChannelHandler(e:Event):void
		{
			_playing = false;
			
			soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundChannelHandler);
			soundChannel.stop();
			soundChannel = null;
			
			if(this.loop)	play(0, this.loop);
			this.dispatchEvent(new Event(Event.SOUND_COMPLETE));
		}
		
		/**
		 *	暂停/播放声音。	pauseToggle
		 */
		public function pause():void
		{
			if(_playing)
			{
				_tempPosition = soundChannel.position;
				stop();
			}
			else
			{
				play(_tempPosition, this.loop);
			}
		}
		
		/**
		 *	停止播放声音。
		 */	
		public function stop():void
		{
			if(_playing)
			{
				_playing = false;
				
				soundChannel.stop();
				soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundChannelHandler);
				soundChannel = null;
			}
		}
		
		/**
		 *	Dispose 
		 */		
		public function dispose():void
		{
			stop();
			
			if(sound)
			{
				sound.removeEventListener(Event.COMPLETE, onLoadCompleteHandler);
				try
				{
					sound.close();
				} 
				catch(error:Error) 
				{
					
				}
				sound = null;
			}
		}
		
		/**	声音音量	 */
		public function get volume():Number	{		return soundChannel.soundTransform.volume;	}
		public function set volume(value:Number):void
		{
			soundChannel.soundTransform = new SoundTransform(value);
		}
		
		/**	声音的平移*/
		public function get pan():Number{	return soundChannel.soundTransform.pan;	}	
		public function set pan(value:Number):void	{	soundChannel.soundTransform = new SoundTransform(volume, value);	}
		
		
		/**	声音文件中当前播放的位置（以毫秒为单位）*/
		public function get position():Number{		return _playing ? soundChannel.position : _tempPosition;	}
		public function set position(value:Number):void
		{
			if(value < 0 || value > length)	return;
			
			stop();
			play(value, this.loop);
		}
		
		/**  当前声音的长度（以毫秒为单位）。 */
		public function get length():Number{	return sound != null ? sound.length : 0;	};
		
		
		/**	获取声音文件路径	*/
		public function get url():String{	return _url;	}
		/**是否正在播放声音*/
		public function get playing():Boolean{ return _playing;	}
	}
}

