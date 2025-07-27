# Import python packages
import streamlit as st
from snowflake.snowpark.context import get_active_session
import snowflake.snowpark.functions as F
from snowflake.ml.registry.registry import Registry
import snowflake.snowpark.types as T

# Write directly to the app
st.title("Monthly Pricing App :athletic_shoe:")
st.write(
    """Navigate to a Nike product line and product. Set the day-of-week 
    pricing for the upcoming month. Click **"Update Prices"** to 
    submit finalized pricing.
    """
)

# Get the current credentials
session = get_active_session()

# Get data and add a comment for columns
df = session.table("pricing").with_column("comment", F.lit(""))

# Dynamic filters
brand = st.selectbox("Nike Product Line:", df.select("brand").distinct())
item = st.selectbox(
    "Product:", df.filter(F.col("brand") == brand).select("item").distinct()
)

# Get product image URL and review sentiment if available
try:
    product_data = df.filter((F.col("brand") == brand) & (F.col("item") == item))
    if hasattr(product_data, 'select') and 'product_image_url' in [col.name.lower() for col in product_data.schema.fields]:
        image_url = product_data.select("product_image_url").first()
        if image_url and image_url[0]:
            col1, col2, col3 = st.columns([1, 1, 1])
            with col1:
                st.image(image_url[0], width=200, caption=f"{brand} - {item}")
            with col2:
                st.markdown(f"### {item}")
                st.markdown(f"**Brand:** {brand}")
            with col3:
                # Try to get review sentiment data
                try:
                    session = get_active_session()
                    sentiment_query = f"""
                    SELECT 
                        avg_sentiment,
                        avg_rating,
                        total_reviews,
                        recommendation_rate,
                        sentiment_category
                    FROM nike_reviews.analytics.product_sentiment_pricing_v 
                    WHERE product_name = '{item}' AND brand_name = '{brand}'
                    """
                    sentiment_data = session.sql(sentiment_query).collect()
                    if sentiment_data:
                        row = sentiment_data[0]
                        st.markdown("**Customer Reviews:**")
                        st.metric("Avg Rating", f"{row[1]:.1f}/5.0" if row[1] else "N/A")
                        st.metric("Total Reviews", row[2] if row[2] else 0)
                        
                        sentiment_score = row[0] if row[0] else 0
                        sentiment_color = "🟢" if sentiment_score > 0.3 else "🔴" if sentiment_score < -0.3 else "🟡"
                        st.write(f"Sentiment: {sentiment_color} {row[4] if row[4] else 'NEUTRAL'}")
                        
                        if row[3]:
                            st.write(f"Recommendation Rate: {row[3]:.1f}%")
                    else:
                        st.markdown("**Customer Reviews:** No data available")
                except Exception:
                    st.markdown("**Customer Reviews:** Not available")
        else:
            # No image available
            col1, col2 = st.columns([1, 1])
            with col1:
                st.markdown(f"### {item}")
                st.markdown(f"**Brand:** {brand}")
            with col2:
                # Show review sentiment even without image
                try:
                    session = get_active_session()
                    sentiment_query = f"""
                    SELECT 
                        avg_sentiment,
                        avg_rating,
                        total_reviews,
                        recommendation_rate,
                        sentiment_category
                    FROM nike_reviews.analytics.product_sentiment_pricing_v 
                    WHERE product_name = '{item}' AND brand_name = '{brand}'
                    """
                    sentiment_data = session.sql(sentiment_query).collect()
                    if sentiment_data:
                        row = sentiment_data[0]
                        st.markdown("**Customer Reviews:**")
                        st.metric("Avg Rating", f"{row[1]:.1f}/5.0" if row[1] else "N/A")
                        st.metric("Total Reviews", row[2] if row[2] else 0)
                        
                        sentiment_score = row[0] if row[0] else 0
                        sentiment_color = "🟢" if sentiment_score > 0.3 else "🔴" if sentiment_score < -0.3 else "🟡"
                        st.write(f"Sentiment: {sentiment_color} {row[4] if row[4] else 'NEUTRAL'}")
                        
                        if row[3]:
                            st.write(f"Recommendation Rate: {row[3]:.1f}%")
                except Exception:
                    st.markdown("**Customer Reviews:** Not available")
except Exception as e:
    # If image loading fails, continue without images
    st.markdown(f"### {item}")
    st.markdown(f"**Brand:** {brand}")

# Provide instructions for updating pricing and using recommendations
st.write(
    """
    View price recommendations and profit lift over current month pricing.
    Adjust **NEW_PRICE** to see the impact on demand and profit.
    """
)

# Display and get updated prices from the data editor object
set_prices = session.create_dataframe(
    st.data_editor(
        df.filter((F.col("brand") == brand) & (F.col("item") == item))
    )
)

# Add a subheader
st.subheader("Forecasted Product Demand Based on Price")

# Define model input features
feature_cols = [
    "price",
    "price_change",
    "base_price",
    "price_hist_dow",
    "price_year_dow",
    "price_month_dow",
    "price_change_hist_dow",
    "price_change_year_dow",
    "price_change_month_dow",
    "price_hist_roll",
    "price_year_roll",
    "price_month_roll",
    "price_change_hist_roll",
    "price_change_year_roll",
    "price_change_month_roll",
]

# Get demand estimation
df_demand = set_prices.join(
    session.table("pricing_detail"), ["brand", "item", "day_of_week"]
).withColumn("price",F.col("new_price")).withColumn("price_change",F.col("PRICE")- F.col("base_price"))

# Get demand estimator model from registry
reg = Registry(session=session)
demand_estimator = reg.get_model("DEMAND_ESTIMATION_MODEL").default

for col in feature_cols :
        df_demand = df_demand.withColumn(col+"_NEW",F.col(col).cast(T.DoubleType())).drop(col).rename(col+"_NEW",col)

df_demand = demand_estimator.run(df_demand, function_name="predict")\
    .select(
    "day_of_week",
    "current_price_demand",
    "new_price",
    "item_cost",
    "average_basket_profit",
    "current_price_profit",
    F.col("demand_estimation").alias("new_price_demand"))

# Demand lift
demand_lift = df_demand.select(
    F.round(
        (
            (F.sum("new_price_demand") - F.sum("current_price_demand"))
            / F.sum("current_price_demand")
        )
        * 100,
        1,
    )
).collect()[0][0]

# Profit lift
profit_lift = (
    df_demand.with_column(
        "new_price_profit",
        F.col("new_price_demand")
        * (F.col("new_price") - F.col("item_cost") + F.col("average_basket_profit")),
    )
    .select(
        F.round(
            (
                (F.sum("new_price_profit") - F.sum("current_price_profit"))
                / F.sum("current_price_profit")
            )
            * 100,
            1,
        )
    )
    .collect()[0][0]
)

# Show KPIs
col1, col2 = st.columns(2)
col1.metric("Total Weekly Demand Lift (%)", demand_lift)
col2.metric("Total Weekly Profit Lift (%)", profit_lift)

# Plot demand
st.line_chart(
    df_demand.with_column("current_price_demand", F.col("current_price_demand") * 0.97),
    x="DAY_OF_WEEK",
    y=["NEW_PRICE_DEMAND", "CURRENT_PRICE_DEMAND"],
)

# Button to submit pricing
if st.button("Update Prices"):
    set_prices.with_column("timestamp", F.current_timestamp()).write.mode(
        "append"
    ).save_as_table("pricing_final")

# Expander to view submitted pricing
with st.expander("View Submitted Prices"):
    st.table(session.table("pricing_final").order_by(F.col("timestamp").desc()))