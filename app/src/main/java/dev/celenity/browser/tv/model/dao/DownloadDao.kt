package dev.celenity.browser.tv.model.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import dev.celenity.browser.tv.model.Download

@Dao
interface DownloadDao {
    @Query("SELECT * FROM downloads")
    suspend fun getAll(): List<Download>

    @Insert
    fun insert(download: Download): Long

    @Update
    fun update(vararg downloads: Download)

    @Delete
    suspend fun delete(download: Download)

    @Query("SELECT * FROM downloads ORDER BY time DESC LIMIT 100 OFFSET :offset")
    suspend fun allByLimitOffset(offset: Long): List<Download>
}
