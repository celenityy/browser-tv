package dev.celenity.browser.tv.activity.main.dialogs.favorites

import android.content.Context
import android.util.AttributeSet
import android.view.LayoutInflater
import android.view.View
import android.widget.FrameLayout
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import dev.celenity.browser.tv.Config
import dev.celenity.browser.tv.R
import dev.celenity.browser.tv.databinding.ViewFavoriteItemBinding
import dev.celenity.browser.tv.model.FavoriteItem
import dev.celenity.browser.tv.singleton.FaviconsPool
import dev.celenity.browser.tv.utils.activity
import dev.celenity.browser.tv.webengine.gecko.HomePageHelper
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Created by PDT on 13.09.2016.
 */
class FavoriteItemView @JvmOverloads constructor(context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0) :
        FrameLayout(context, attrs, defStyleAttr) {
    private lateinit var vb: ViewFavoriteItemBinding
    var favorite: FavoriteItem? = null
        private set
    var listener: Listener? = null

    interface Listener {
        fun onDeleteClick(favorite: FavoriteItem)
        fun onEditClick(favorite: FavoriteItem)
    }

    init {
        init()
    }

    private fun init() {
        vb = ViewFavoriteItemBinding.inflate(LayoutInflater.from(context), this, true)

        vb.ibDelete.setOnClickListener { favorite?.let { listener?.onDeleteClick(it)} }

        vb.llContent.setOnClickListener {  favorite?.let {listener?.onEditClick(it)} }
    }

    fun bind(favorite: FavoriteItem, editMode: Boolean) {
        this.favorite = favorite
        vb.ibDelete.visibility = if (editMode) View.VISIBLE else View.GONE
        vb.llContent.isClickable = editMode
        vb.llContent.isFocusable = editMode
        vb.tvTitle.text = favorite.title
        vb.tvUrl.text = favorite.url
        vb.ivIcon.setImageResource(R.drawable.ic_not_available)
        val url = favorite.url
        if (url != null && url != HomePageHelper.HOME_PAGE_URL) {
            val scope = (activity as AppCompatActivity).lifecycleScope
            scope.launch(Dispatchers.Main) {
                val favicon = FaviconsPool.get(url)
                if (url != this@FavoriteItemView.favorite?.url) return@launch //url was changed while loading favicon
                if (!isAttachedToWindow) return@launch
                favicon?.let {
                    vb.ivIcon.setImageBitmap(it)
                } ?: run {
                    vb.ivIcon.setImageResource(R.drawable.ic_not_available)
                }
            }
        }
    }
}
