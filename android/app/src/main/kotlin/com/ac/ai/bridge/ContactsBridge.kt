package com.ac.ai.bridge

import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.ContactsContract
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class ContactsBridge(private val context: Context) {
    companion object {
        private const val TAG = "ContactsBridge"
        const val CHANNEL = "com.ac.ai/contacts"
    }

    private var methodChannel: MethodChannel? = null

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
        setupMethodCallHandler()
    }

    private fun setupMethodCallHandler() {
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getContacts" -> {
                    val query = call.argument<String>("query")
                    val contacts = getContacts(query)
                    result.success(contacts)
                }
                "getContactByPhone" -> {
                    val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                    val contact = getContactByPhone(phoneNumber)
                    result.success(contact)
                }
                "addContact" -> {
                    val name = call.argument<String>("name") ?: ""
                    val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                    val success = addContact(name, phoneNumber)
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun getContacts(query: String?): String {
        return try {
            val contactsList = JSONArray()
            val contentResolver: ContentResolver = context.contentResolver
            
            val projection = arrayOf(
                ContactsContract.Contacts._ID,
                ContactsContract.Contacts.DISPLAY_NAME,
                ContactsContract.Contacts.HAS_PHONE_NUMBER
            )
            
            val selection = if (query != null && query.isNotEmpty()) {
                "${ContactsContract.Contacts.DISPLAY_NAME} LIKE ?"
            } else null
            
            val selectionArgs = if (query != null && query.isNotEmpty()) {
                arrayOf("%$query%")
            } else null
            
            val cursor: Cursor? = contentResolver.query(
                ContactsContract.Contacts.CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                ContactsContract.Contacts.DISPLAY_NAME + " ASC"
            )
            
            cursor?.use {
                while (it.moveToNext()) {
                    val id = it.getString(it.getColumnIndex(ContactsContract.Contacts._ID))
                    val name = it.getString(it.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME))
                    val hasPhone = it.getInt(it.getColumnIndex(ContactsContract.Contacts.HAS_PHONE_NUMBER))
                    
                    if (hasPhone > 0) {
                        val phones = getPhoneNumbers(id)
                        val contact = JSONObject().apply {
                            put("id", id)
                            put("displayName", name)
                            put("phones", phones)
                        }
                        contactsList.put(contact)
                    }
                }
            }
            
            contactsList.toString()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting contacts", e)
            "[]"
        }
    }

    private fun getPhoneNumbers(contactId: String): JSONArray {
        val phones = JSONArray()
        val contentResolver: ContentResolver = context.contentResolver
        
        val phoneCursor: Cursor? = contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            null,
            ContactsContract.CommonDataKinds.Phone.CONTACT_ID + " = ?",
            arrayOf(contactId),
            null
        )
        
        phoneCursor?.use {
            while (it.moveToNext()) {
                val phoneNumber = it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER))
                val phoneType = it.getInt(it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.TYPE))
                val typeLabel = ContactsContract.CommonDataKinds.Phone.getTypeLabel(context.resources, phoneType, "")
                
                phones.put(JSONObject().apply {
                    put("number", phoneNumber)
                    put("type", typeLabel)
                })
            }
        }
        
        return phones
    }

    fun getContactByPhone(phoneNumber: String): String? {
        return try {
            val contentResolver: ContentResolver = context.contentResolver
            val uri = Uri.withAppendedPath(
                ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
                Uri.encode(phoneNumber)
            )
            
            val projection = arrayOf(
                ContactsContract.PhoneLookup._ID,
                ContactsContract.PhoneLookup.DISPLAY_NAME
            )
            
            contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val id = cursor.getString(cursor.getColumnIndex(ContactsContract.PhoneLookup._ID))
                    val name = cursor.getString(cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME))
                    
                    return JSONObject().apply {
                        put("id", id)
                        put("displayName", name)
                        put("phoneNumber", phoneNumber)
                    }.toString()
                }
            }
            null
        } catch (e: Exception) {
            Log.e(TAG, "Error getting contact by phone", e)
            null
        }
    }

    fun addContact(name: String, phoneNumber: String): Boolean {
        return try {
            val ops = ArrayList<android.content.ContentProviderOperation>()
            
            ops.add(android.content.ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
                .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, null)
                .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, null)
                .build())
            
            ops.add(android.content.ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
                .withValue(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, name)
                .build())
            
            ops.add(android.content.ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, phoneNumber)
                .withValue(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE)
                .build())
            
            context.contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error adding contact", e)
            false
        }
    }
}
