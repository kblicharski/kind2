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
#include "org_zeromq_czmq_ZhttpRequest.h"

JNIEXPORT jlong JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1new (JNIEnv *env, jclass c)
{
    //  Disable CZMQ signal handling; allow Java to deal with it
    zsys_handler_set (NULL);
    jlong new_ = (jlong) (intptr_t) zhttp_request_new ();
    return new_;
}

JNIEXPORT void JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1destroy (JNIEnv *env, jclass c, jlong self)
{
    zhttp_request_destroy ((zhttp_request_t **) &self);
}

JNIEXPORT jlong JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1recv (JNIEnv *env, jclass c, jlong self, jlong sock)
{
    jlong recv_ = (jlong) (intptr_t) zhttp_request_recv ((zhttp_request_t *) (intptr_t) self, (zsock_t *) (intptr_t) sock);
    return recv_;
}

JNIEXPORT jint JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1send (JNIEnv *env, jclass c, jlong self, jlong client, jint timeout, jlong arg, jlong arg2)
{
    jint send_ = (jint) zhttp_request_send ((zhttp_request_t *) (intptr_t) self, (zhttp_client_t *) (intptr_t) client, (int) timeout, (void *) (intptr_t) arg, (void *) (intptr_t) arg2);
    return send_;
}

JNIEXPORT jstring JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1method (JNIEnv *env, jclass c, jlong self)
{
    char *method_ = (char *) zhttp_request_method ((zhttp_request_t *) (intptr_t) self);
    jstring return_string_ = (*env)->NewStringUTF (env, method_);
    return return_string_;
}

JNIEXPORT void JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1setMethod (JNIEnv *env, jclass c, jlong self, jstring method)
{
    char *method_ = (char *) (*env)->GetStringUTFChars (env, method, NULL);
    zhttp_request_set_method ((zhttp_request_t *) (intptr_t) self, method_);
    (*env)->ReleaseStringUTFChars (env, method, method_);
}

JNIEXPORT jstring JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1url (JNIEnv *env, jclass c, jlong self)
{
    char *url_ = (char *) zhttp_request_url ((zhttp_request_t *) (intptr_t) self);
    jstring return_string_ = (*env)->NewStringUTF (env, url_);
    return return_string_;
}

JNIEXPORT void JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1setUrl (JNIEnv *env, jclass c, jlong self, jstring url)
{
    char *url_ = (char *) (*env)->GetStringUTFChars (env, url, NULL);
    zhttp_request_set_url ((zhttp_request_t *) (intptr_t) self, url_);
    (*env)->ReleaseStringUTFChars (env, url, url_);
}

JNIEXPORT jstring JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1contentType (JNIEnv *env, jclass c, jlong self)
{
    char *content_type_ = (char *) zhttp_request_content_type ((zhttp_request_t *) (intptr_t) self);
    jstring return_string_ = (*env)->NewStringUTF (env, content_type_);
    return return_string_;
}

JNIEXPORT void JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1setContentType (JNIEnv *env, jclass c, jlong self, jstring content_type)
{
    char *content_type_ = (char *) (*env)->GetStringUTFChars (env, content_type, NULL);
    zhttp_request_set_content_type ((zhttp_request_t *) (intptr_t) self, content_type_);
    (*env)->ReleaseStringUTFChars (env, content_type, content_type_);
}

JNIEXPORT jlong JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1contentLength (JNIEnv *env, jclass c, jlong self)
{
    jlong content_length_ = (jlong) zhttp_request_content_length ((zhttp_request_t *) (intptr_t) self);
    return content_length_;
}

JNIEXPORT jlong JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1headers (JNIEnv *env, jclass c, jlong self)
{
    jlong headers_ = (jlong) (intptr_t) zhttp_request_headers ((zhttp_request_t *) (intptr_t) self);
    return headers_;
}

JNIEXPORT jstring JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1content (JNIEnv *env, jclass c, jlong self)
{
    char *content_ = (char *) zhttp_request_content ((zhttp_request_t *) (intptr_t) self);
    jstring return_string_ = (*env)->NewStringUTF (env, content_);
    return return_string_;
}

JNIEXPORT jstring JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1getContent (JNIEnv *env, jclass c, jlong self)
{
    char *get_content_ = (char *) zhttp_request_get_content ((zhttp_request_t *) (intptr_t) self);
    jstring return_string_ = (*env)->NewStringUTF (env, get_content_);
    zstr_free (&get_content_);
    return return_string_;
}

JNIEXPORT void JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1setContentConst (JNIEnv *env, jclass c, jlong self, jstring content)
{
    char *content_ = (char *) (*env)->GetStringUTFChars (env, content, NULL);
    zhttp_request_set_content_const ((zhttp_request_t *) (intptr_t) self, content_);
    (*env)->ReleaseStringUTFChars (env, content, content_);
}

JNIEXPORT void JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1resetContent (JNIEnv *env, jclass c, jlong self)
{
    zhttp_request_reset_content ((zhttp_request_t *) (intptr_t) self);
}

JNIEXPORT jboolean JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1match (JNIEnv *env, jclass c, jlong self, jstring method, jstring path)
{
    char *method_ = (char *) (*env)->GetStringUTFChars (env, method, NULL);
    char *path_ = (char *) (*env)->GetStringUTFChars (env, path, NULL);
    jboolean match_ = (jboolean) zhttp_request_match ((zhttp_request_t *) (intptr_t) self, method_, path_);
    (*env)->ReleaseStringUTFChars (env, method, method_);
    (*env)->ReleaseStringUTFChars (env, path, path_);
    return match_;
}

JNIEXPORT void JNICALL
Java_org_zeromq_czmq_ZhttpRequest__1_1test (JNIEnv *env, jclass c, jboolean verbose)
{
    zhttp_request_test ((bool) verbose);
}

