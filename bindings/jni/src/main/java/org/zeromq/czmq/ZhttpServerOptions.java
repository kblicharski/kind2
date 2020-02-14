/*
################################################################################
#  THIS FILE IS 100% GENERATED BY ZPROJECT; DO NOT EDIT EXCEPT EXPERIMENTALLY  #
#  Read the zproject/README.md for information about making permanent changes. #
################################################################################
*/
package org.zeromq.czmq;

import org.scijava.nativelib.NativeLoader;

public class ZhttpServerOptions implements AutoCloseable{
    static {
        if (System.getProperty("java.vm.vendor").contains("Android")) {
            System.loadLibrary("czmqjni");
        } else {
            try {
                NativeLoader.loadLibrary("czmqjni");
            } catch (Exception e) {
                System.exit (-1);
            }
        }
    }
    public long self;
    /*
    Create a new zhttp_server_options.
    */
    native static long __new ();
    public ZhttpServerOptions () {
        /*  TODO: if __new fails, self is null...            */
        self = __new ();
    }
    public ZhttpServerOptions (long pointer) {
        self = pointer;
    }
    /*
    Create options from config tree.
    */
    native static long __fromConfig (long config);
    public static ZhttpServerOptions fromConfig (Zconfig config) {
        return new ZhttpServerOptions (__fromConfig (config.self));
    }
    /*
    Destroy the zhttp_server_options.
    */
    native static void __destroy (long self);
    @Override
    public void close () {
        __destroy (self);
        self = 0;
    }
    /*
    Get the server listening port.
    */
    native static int __port (long self);
    public int port () {
        return __port (self);
    }
    /*
    Set the server listening port
    */
    native static void __setPort (long self, int port);
    public void setPort (int port) {
        __setPort (self, port);
    }
    /*
    Get the address sockets should connect to in order to receive requests.
    */
    native static String __backendAddress (long self);
    public String backendAddress () {
        return __backendAddress (self);
    }
    /*
    Set the address sockets should connect to in order to receive requests.
    */
    native static void __setBackendAddress (long self, String address);
    public void setBackendAddress (String address) {
        __setBackendAddress (self, address);
    }
    /*
    Self test of this class.
    */
    native static void __test (boolean verbose);
    public static void test (boolean verbose) {
        __test (verbose);
    }
}
