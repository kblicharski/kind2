/*
################################################################################
#  THIS FILE IS 100% GENERATED BY ZPROJECT; DO NOT EDIT EXCEPT EXPERIMENTALLY  #
#  Read the zproject/README.md for information about making permanent changes. #
################################################################################
*/
#include <stdio.h>
#include <stdlib.h>
#include <jni.h>
#include "czmq.h"
#include "org_zeromq_czmq_Zframe.h"

JNIEXPORT jlong JNICALL
Java_org_zeromq_czmq_Zframe__1_1new (JNIEnv *env, jclass c, jbyteArray data, jlong size)
{
    jbyte *data_ = (byte *) (*env)->GetByteArrayElements (env, data, 0);
    //  Disable CZMQ signal handling; allow Java to deal with it
    zsys_handler_set (NULL);
    jlong new_ = (jlong) (intptr_t) zframe_new (data_, (size_t) size);
    (*env)->ReleaseByteArrayElements (env, data, (jbyte *) data_, 0);
    return new_;
}

JNIEXPORT jlong JNICALL
Java_org_zeromq_czmq_Zframe__1_1newEmpty (JNIEnv *env, jclass c)
{
    jlong new_empty_ = (jlong) (intptr_t) zframe_new_empty ();
    return new_empty_;
}

JNIEXPORT jlong JNICALL
Java_org_zeromq_czmq_Zframe__1_1from (JNIEnv *env, jclass c, jstring string)
{
    char *string_ = (char *) (*env)->GetStringUTFChars (env, string, NULL);
    jlong from_ = (jlong) (intptr_t) zframe_from (string_);
    (*env)->ReleaseStringUTFChars (env, string, string_);
    return from_;
}

JNIEXPORT jlong JNICALL
Java_org_zeromq_czmq_Zframe__1_1recv (JNIEnv *env, jclass c, jlong source)
{
    jlong recv_ = (jlong) (intptr_t) zframe_recv ((void *) (intptr_t) source);
    return recv_;
}

JNIEXPORT void JNICALL
Java_org_zeromq_czmq_Zframe__1_1destroy (JNIEnv *env, jclass c, jlong self)
{
    zframe_destroy ((zframe_t **) &self);
}

JNIEXPORT jlong JNICALL
Java_org_zeromq_czmq_Zframe__1_1send (JNIEnv *env, jclass c, jlong self, jlong dest, jint flags)
{
    jint send_ = (jint) zframe_send ((zframe_t **) &self, (void *) (intptr_t) dest, (int) flags);
    return self;
}

JNIEXPORT jlong JNICALL
Java_org_zeromq_czmq_Zframe__1_1size (JNIEnv *env, jclass c, jlong self)
{
    jlong size_ = (jlong) zframe_size ((zframe_t *) (intptr_t) self);
    return size_;
}

JNIEXPORT jbyteArray JNICALL
Java_org_zeromq_czmq_Zframe__1_1data (JNIEnv *env, jclass c, jlong self)
{
    jbyte *data_ = (jbyte *) zframe_data ((zframe_t *) (intptr_t) self);
    jint return_size_ = (jint) zframe_size ((zframe_t *) (intptr_t) self);
    jbyteArray return_data_ = (*env)->NewByteArray (env, return_size_);
    (*env)->SetByteArrayRegion (env, return_data_, 0, return_size_, (jbyte *) data_);
    return return_data_;
}

JNIEXPORT jstring JNICALL
Java_org_zeromq_czmq_Zframe__1_1meta (JNIEnv *env, jclass c, jlong self, jstring property)
{
    char *property_ = (char *) (*env)->GetStringUTFChars (env, property, NULL);
    char *meta_ = (char *) zframe_meta ((zframe_t *) (intptr_t) self, property_);
    jstring return_string_ = (*env)->NewStringUTF (env, meta_);
    (*env)->ReleaseStringUTFChars (env, property, property_);
    return return_string_;
}

JNIEXPORT jlong JNICALL
Java_org_zeromq_czmq_Zframe__1_1dup (JNIEnv *env, jclass c, jlong self)
{
    jlong dup_ = (jlong) (intptr_t) zframe_dup ((zframe_t *) (intptr_t) self);
    return dup_;
}

JNIEXPORT jstring JNICALL
Java_org_zeromq_czmq_Zframe__1_1strhex (JNIEnv *env, jclass c, jlong self)
{
    char *strhex_ = (char *) zframe_strhex ((zframe_t *) (intptr_t) self);
    jstring return_string_ = (*env)->NewStringUTF (env, strhex_);
    zstr_free (&strhex_);
    return return_string_;
}

JNIEXPORT jstring JNICALL
Java_org_zeromq_czmq_Zframe__1_1strdup (JNIEnv *env, jclass c, jlong self)
{
    char *strdup_ = (char *) zframe_strdup ((zframe_t *) (intptr_t) self);
    jstring return_string_ = (*env)->NewStringUTF (env, strdup_);
    zstr_free (&strdup_);
    return return_string_;
}

JNIEXPORT jboolean JNICALL
Java_org_zeromq_czmq_Zframe__1_1streq (JNIEnv *env, jclass c, jlong self, jstring string)
{
    char *string_ = (char *) (*env)->GetStringUTFChars (env, string, NULL);
    jboolean streq_ = (jboolean) zframe_streq ((zframe_t *) (intptr_t) self, string_);
    (*env)->ReleaseStringUTFChars (env, string, string_);
    return streq_;
}

JNIEXPORT jint JNICALL
Java_org_zeromq_czmq_Zframe__1_1more (JNIEnv *env, jclass c, jlong self)
{
    jint more_ = (jint) zframe_more ((zframe_t *) (intptr_t) self);
    return more_;
}

JNIEXPORT void JNICALL
Java_org_zeromq_czmq_Zframe__1_1setMore (JNIEnv *env, jclass c, jlong self, jint more)
{
    zframe_set_more ((zframe_t *) (intptr_t) self, (int) more);
}

JNIEXPORT jint JNICALL
Java_org_zeromq_czmq_Zframe__1_1routingId (JNIEnv *env, jclass c, jlong self)
{
    jint routing_id_ = (jint) zframe_routing_id ((zframe_t *) (intptr_t) self);
    return routing_id_;
}

JNIEXPORT void JNICALL
Java_org_zeromq_czmq_Zframe__1_1setRoutingId (JNIEnv *env, jclass c, jlong self, jint routing_id)
{
    zframe_set_routing_id ((zframe_t *) (intptr_t) self, (uint32_t) routing_id);
}

JNIEXPORT jstring JNICALL
Java_org_zeromq_czmq_Zframe__1_1group (JNIEnv *env, jclass c, jlong self)
{
    char *group_ = (char *) zframe_group ((zframe_t *) (intptr_t) self);
    jstring return_string_ = (*env)->NewStringUTF (env, group_);
    return return_string_;
}

JNIEXPORT jint JNICALL
Java_org_zeromq_czmq_Zframe__1_1setGroup (JNIEnv *env, jclass c, jlong self, jstring group)
{
    char *group_ = (char *) (*env)->GetStringUTFChars (env, group, NULL);
    jint set_group_ = (jint) zframe_set_group ((zframe_t *) (intptr_t) self, group_);
    (*env)->ReleaseStringUTFChars (env, group, group_);
    return set_group_;
}

JNIEXPORT jboolean JNICALL
Java_org_zeromq_czmq_Zframe__1_1eq (JNIEnv *env, jclass c, jlong self, jlong other)
{
    jboolean eq_ = (jboolean) zframe_eq ((zframe_t *) (intptr_t) self, (zframe_t *) (intptr_t) other);
    return eq_;
}

JNIEXPORT void JNICALL
Java_org_zeromq_czmq_Zframe__1_1reset (JNIEnv *env, jclass c, jlong self, jbyteArray data, jlong size)
{
    jbyte *data_ = (byte *) (*env)->GetByteArrayElements (env, data, 0);
    zframe_reset ((zframe_t *) (intptr_t) self, data_, (size_t) size);
    (*env)->ReleaseByteArrayElements (env, data, (jbyte *) data_, 0);
}

JNIEXPORT void JNICALL
Java_org_zeromq_czmq_Zframe__1_1print (JNIEnv *env, jclass c, jlong self, jstring prefix)
{
    char *prefix_ = (char *) (*env)->GetStringUTFChars (env, prefix, NULL);
    zframe_print ((zframe_t *) (intptr_t) self, prefix_);
    (*env)->ReleaseStringUTFChars (env, prefix, prefix_);
}

JNIEXPORT jboolean JNICALL
Java_org_zeromq_czmq_Zframe__1_1is (JNIEnv *env, jclass c, jlong self)
{
    jboolean is_ = (jboolean) zframe_is ((void *) (intptr_t) self);
    return is_;
}

JNIEXPORT void JNICALL
Java_org_zeromq_czmq_Zframe__1_1test (JNIEnv *env, jclass c, jboolean verbose)
{
    zframe_test ((bool) verbose);
}

