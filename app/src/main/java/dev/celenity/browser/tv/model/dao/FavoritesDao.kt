package dev.celenity.browser.tv.model.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import dev.celenity.browser.tv.model.FavoriteItem
import dev.celenity.browser.tv.model.HistoryItem

@Dao
interface FavoritesDao {
    @Query("SELECT * FROM favorites WHERE parent=0 AND home_page_bookmark=:homePageBookmarks ORDER BY id DESC")
    suspend fun getAll(homePageBookmarks: Boolean = false): List<FavoriteItem>

    @Query("SELECT * FROM favorites WHERE parent=0 AND home_page_bookmark=1 ORDER BY i_order ASC")
    suspend fun getHomePageBookmarks(): List<FavoriteItem>

    @Insert
    suspend fun insert(item: FavoriteItem): Long

    @Update
    suspend fun update(item: FavoriteItem)

    @Delete
    suspend fun delete(item: FavoriteItem)

    @Query("DELETE FROM favorites WHERE id=:id")
    suspend fun delete(id: Long)

    @Query("SELECT * FROM favorites WHERE id=:id")
    suspend fun getById(id: Long): FavoriteItem?
}
