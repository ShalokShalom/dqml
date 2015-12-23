module dqml.qobject;

import std.stdio;
import std.format;
import std.conv;
import std.container;
import std.traits;
import std.string;
import std.algorithm;
import dqml.dothersideinterface;
import dqml.qmetatype;
import dqml.qvariant;

public class QObject
{
    public this()
    {
        this(false);
    }

    protected this(bool disableDosCalls)
    {
        this.disableDosCalls = disableDosCalls;
        if (!this.disableDosCalls)
        {
            dos_qobject_create(this.vptr, cast(void*)this, &staticSlotCallback);
            qobjectInit();
        }
    }

    package this(void* vptr)
    {
        this.vptr = vptr;
        this(true);
    }

    ~this()
    {
        if (!this.disableDosCalls)
        {
            dos_qobject_delete(this.vptr);
            this.vptr = null;
        }
    }

    public void* voidPointer()
    {
        return this.vptr;
    }

    protected void qobjectInit()
    {}

    protected void onSlotCalled(QVariant slotName, QVariant[] parameters)
    {
    }

    protected void registerSlot(string name, QMetaType[] types)
    {
        int index = -1;
        int  length = cast(int)types.length;
        int[] array = to!(int[])(types);
        dos_qobject_slot_create(this.vptr,
                                name.toStringz(),
                                length,
                                array.ptr,
                                index);
    }

    protected void registerSignal(string name, QMetaType[] types)
    {
        int index = -1;
        int length = cast(int)types.length;
        int[] array = length > 0 ? to!(int[])(types) : null;
        dos_qobject_signal_create(this.vptr,
                                  name.toStringz(),
                                  length,
                                  array.ptr,
                                  index);
    }

    protected bool connect(QObject sender,
                           string signal,
                           string method,
                           ConnectionType type = ConnectionType.Auto)
    {
        return QObject.connect(sender, signal, this, method, type);
    }

    protected bool disconnect(QObject sender,
                              string signal,
                              string method)
    {
        return QObject.disconnect(sender, signal, this, method);
    }

    protected void registerProperty(string name,
                                    QMetaType type,
                                    string readSlotName,
                                    string writeSlotName,
                                    string notifySignalName)
    {
        dos_qobject_property_create(this.vptr,
                                    name.toStringz(),
                                    type,
                                    readSlotName.toStringz(),
                                    writeSlotName.toStringz(),
                                    notifySignalName.toStringz());
    }

    protected void emit(T)(string signalName, T t)
    {
        emit(signalName, new QVariant(t));
    }

    protected void emit(string signalName, QVariant value)
    {
        QVariant[] array = [value];
        emit(signalName, array);
    }

    protected void emit(string signalName, QVariant[] arguments = null)
    {
        int length = cast(int)arguments.length;
        void*[] array = null;
        if (length > 0) {
            array = new void*[length];
            foreach (int i, QVariant v; arguments)
                array[i] = v.voidPointer();
        }
        dos_qobject_signal_emit(this.vptr,
                                signalName.toStringz(),
                                length,
                                array.ptr);
    }

    protected extern (C) static void staticSlotCallback(void* qObjectPtr,
                                                        void* rawSlotName,
                                                        int numParameters,
                                                        void** parametersArray)
    {
        QVariant[] parameters = new QVariant[numParameters];
        for (int i = 0; i < numParameters; ++i)
            parameters[i] = new QVariant(parametersArray[i]);
        QObject qObject = cast(QObject) qObjectPtr;
        QVariant slotName = new QVariant(rawSlotName);
        qObject.onSlotCalled(slotName, parameters);
    }

    protected static bool connect(QObject sender,
                                  string signal,
                                  QObject receiver,
                                  string method,
                                  ConnectionType type = ConnectionType.Auto)
    {
        bool result;
        dos_qobject_signal_connect(sender.voidPointer,
                                   signal.toStringz,
                                   receiver.voidPointer,
                                   method.toStringz,
                                   type,
                                   result);
        return result;
    }

    protected static bool disconnect(QObject sender,
                                     string signal,
                                     QObject receiver,
                                     string method)
    {
        bool result;
        dos_qobject_signal_disconnect(sender.voidPointer,
                                      signal.toStringz,
                                      receiver.voidPointer,
                                      method.toStringz,
                                      result);
        return result;
    }

    protected void* vptr;
    protected bool disableDosCalls;
}

enum ConnectionType : int
{
    Auto = 0,
    Direct,
    Queued,
    BlockingQueued,

    Unique = 0x80
}
