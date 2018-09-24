package ti.mely;

import java.util.HashMap;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollProxy;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.kroll.KrollFunction;

import android.os.Handler;

@Kroll.proxy(creatableInModule = TimelyModule.class)
public class TimerProxy extends KrollProxy {

	private Handler _taskHandler = new Handler();
	private Boolean _isActive = false;
	private Runnable _task = null;
	private double _interval = 1000;
	private long _counter = 0;
	private boolean _debug = false;

	public TimerProxy() {
		super();
	}

	private void sendTickFired() {

		if (hasListeners("onIntervalChange")) {

			_counter++;

			HashMap<String, Object> event = new HashMap<String, Object>();
			event.put("interval", _interval);
			event.put("intervalCount", _counter);
			fireEvent("onIntervalChange", event);

			if (_debug) {
				Log.d(TimelyModule.MODULE_SHORT_NAME, "onIntervalChange event fired");
			}
		}
	}

	@Kroll.method
	public void start(KrollDict args) {

		if (args.containsKey("interval")) {
			_interval = args.getDouble("interval");
		}

		_debug = args.optBoolean("debug", false);

		if (_debug) {
			Log.d(TimelyModule.MODULE_SHORT_NAME, "Starting Timer");
		}

		_task = new Runnable() {

			public void run() {
				if (_debug) {
					Log.d(TimelyModule.MODULE_SHORT_NAME, "Timer Fired");
				}

				if (_isActive) {
					sendTickFired();
					_taskHandler.postDelayed(this, (long) _interval);
				} else {
					_taskHandler.removeCallbacks(_task);
				}
			}
		};

		_taskHandler.postDelayed(_task, (long) _interval);
		_isActive = true;
	}

	@Kroll.method
	public void stop() {
		if (_debug) {
			Log.d(TimelyModule.MODULE_SHORT_NAME, "Stopping Timer");
		}

		_taskHandler.removeCallbacks(_task);
		_isActive = false;
		_counter = 0;
	}

	@Kroll.method
	public void setTimeout(final KrollFunction callback, final double interval) {

		if (interval > 0) {
			_interval = interval;
		}
		if (_debug) {
			Log.d(TimelyModule.MODULE_SHORT_NAME, "start setTimeout with interval " + interval);
		}

		_task = new Runnable() {
			public void run() {
				if (_isActive) {
					stop();
					KrollDict map = new KrollDict();
					map.put("type", "timeout");
					callback.call(getKrollObject(), map);
					map = null;
					if (_debug) {
						Log.d(TimelyModule.MODULE_SHORT_NAME, "setTimeout fired");
					}
				}
			}
		};
		_taskHandler.postDelayed(_task, (long) _interval);
		_isActive = true;
	}

	@Kroll.method
	public void clearTimeout() {
		stop();
	}

	@Kroll.method
	public void setInterval(final KrollFunction callback, final double interval) {

		if (interval > 0) {
			_interval = interval;
		}
		if (_debug) {
			Log.d(TimelyModule.MODULE_SHORT_NAME, "start setInterval with interval " + interval);
		}

		_task = new Runnable() {
			public void run() {
				if (_isActive) {

					KrollDict map = new KrollDict();
					map.put("type", "interval");
					callback.call(getKrollObject(), map);
					map = null;
					if (_debug) {
						Log.d(TimelyModule.MODULE_SHORT_NAME, "setInterval fired");
					}
					_taskHandler.postDelayed(this, (long) _interval);
				} else {
					stop();
				}
			}
		};
		_taskHandler.postDelayed(_task, (long) _interval);
		_isActive = true;
	}

	@Kroll.method
	public void clearInterval() {
		stop();
	}
}
