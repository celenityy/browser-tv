package dev.celenity.browser.tv.model.dao

import androidx.room.*
import dev.celenity.browser.tv.model.HostConfig

@Dao
interface HostsDao {
    @Query("SELECT * FROM hosts WHERE host_name = :name")
    fun findByHostName(name: String): HostConfig?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(item: HostConfig): Long

    @Update
    suspend fun update(item: HostConfig)
}
